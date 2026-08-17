from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from contextlib import redirect_stdout
from io import StringIO
from pathlib import Path
import sys
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "lib"))

import settings_core

from settings_core import (
    apply_settings,
    build_install_commands,
    build_plan,
    load_group,
    parse_setting,
    resolve_lineage,
    validate_setup,
)


class SettingsCoreTests(unittest.TestCase):
    def test_lineage_resolves_gnome_parent_chains(self) -> None:
        self.assertEqual(resolve_lineage("silverblue"), ["default", "gnome", "silverblue"])
        self.assertEqual(resolve_lineage("bluefin"), ["default", "gnome", "bluefin"])
        self.assertEqual(resolve_lineage("hyprland"), ["default", "hyprland"])
        self.assertEqual(resolve_lineage("mate-i3"), ["default", "mate-i3"])

    def test_gnome_plan_keeps_old_apply_order(self) -> None:
        plan = build_plan("gnome")
        self.assertTrue(all(script["number"] < 50 for script in plan["scripts"]["pre"]))
        self.assertTrue(all(script["number"] >= 50 for script in plan["scripts"]["post"]))
        self.assertTrue(
            all(script["name"][2] == "-" for phase in plan["scripts"].values() for script in phase)
        )
        self.assertIn(".bashrc", {setting["target"] for setting in plan["settings"]})

    def test_bluefin_selects_gnome_extensions(self) -> None:
        plan = build_plan("bluefin")
        self.assertIn("settings-updatecheck@localhost", plan["gnome"]["extensions"])
        self.assertIn(
            "panel-workspace-scroll@polymeilex.github.io",
            plan["gnome"]["remote_extensions"],
        )

    def test_empty_gnome_selection_still_runs_extension_reconciliation(self) -> None:
        plan = build_plan("gnome")
        self.assertEqual(plan["gnome"]["extensions"], [])
        self.assertEqual(plan["gnome"]["remote_extensions"], [])

        with redirect_stdout(StringIO()):
            with patch.object(settings_core.subprocess, "check_call") as check_call:
                settings_core._run_gnome_extensions_action(plan, Path("/tmp/test-home"))

        argv = check_call.call_args.args[0]
        env = check_call.call_args.kwargs["env"]
        self.assertEqual(argv[0], "bash")
        self.assertEqual(env["SETTINGS_GNOME_EXTENSIONS"], "")
        self.assertEqual(env["SETTINGS_GNOME_REMOTE_EXTENSIONS"], "")
        self.assertEqual(env["SETTINGS_GNOME_EXTENSIONS_FORCE"], "1")

    def test_group_metadata_loads_packages(self) -> None:
        group = load_group("fedora-deps")
        self.assertIn("kitty", group["packages"])
        self.assertIn("dnf", group["providers"])

    def test_install_commands_are_built_from_inherited_groups(self) -> None:
        plan = build_plan("silverblue")
        commands = build_install_commands(plan, provider="rpm-ostree")
        package_args = []
        actions = {action["name"] for action in plan["install"]["actions"]}
        for command in commands:
            if command["operation"] == "install":
                package_args.extend(command["argv"][2:])
        self.assertIn("android-tools", package_args)
        self.assertIn("openh264", package_args)
        self.assertIn("enable-rpmfusion", actions)
        self.assertIn("enable-flathub", actions)

    def test_selected_group_does_not_require_unrelated_provider(self) -> None:
        plan = build_plan("silverblue")
        commands = build_install_commands(plan, provider="dnf", selected="fedora-tools")
        self.assertEqual({command["group"] for command in commands}, {"fedora-tools"})

    def test_brew_only_group_uses_brew_provider_in_mixed_plan(self) -> None:
        plan = build_plan("bluefin")
        commands = build_install_commands(plan, provider="rpm-ostree")
        brew_commands = [command for command in commands if command["group"] == "bluefin-brew"]
        self.assertEqual(len(brew_commands), 1)
        self.assertEqual(brew_commands[0]["provider"], "brew")
        self.assertIn("neovim", brew_commands[0]["argv"])

    def test_snap_group_supports_classic_installs(self) -> None:
        plan = {"install": {"group_details": [load_group("snap-tools")]}}
        commands = build_install_commands(plan, provider="rpm-ostree")
        self.assertEqual(commands[0]["provider"], "snap")
        self.assertEqual(commands[0]["operation"], "install-classic")
        self.assertIn("code", commands[0]["argv"])

    def test_one_off_snap_group_can_be_selected(self) -> None:
        from settings_core import run_install

        output = StringIO()
        with redirect_stdout(output):
            run_install("default", "snap-tools", dry_run=True, provider="snap")
        self.assertIn("-> install group snap-tools (snap install-classic)", output.getvalue())

    def test_comment_setting_marker_is_preserved(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "s.example"
            path.write_text("# .example\nvalue\n")
            parsed = parse_setting(path, "fixture")
            self.assertEqual(parsed["target"], ".example")
            self.assertFalse(parsed["strip_first_line"])

    def test_plain_setting_marker_is_removed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "s.example"
            path.write_text(".example\nvalue\n")
            parsed = parse_setting(path, "fixture")
            self.assertEqual(parsed["target"], ".example")
            self.assertTrue(parsed["strip_first_line"])

    def test_saved_setting_content_preserves_plain_target_marker(self) -> None:
        setting = {"path": "setups/default/s.example", "strip_first_line": True}
        saved = settings_core._saved_setting_bytes(
            setting,
            b".example\nold value\n",
            b"new value\n",
        )
        self.assertEqual(saved, b".example\nnew value\n")

    def test_save_plan_reads_installed_symlink_content(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "repo"
            home = Path(tmp) / "home"
            source = root / "setups/default/s.example"
            installed = Path(tmp) / "state/s.example"
            source.parent.mkdir(parents=True)
            installed.parent.mkdir(parents=True)
            home.mkdir()
            source.write_text(".example\nold value\n")
            installed.write_text("imperative edit\n")
            (home / ".example").symlink_to(installed)
            plan = {
                "settings": [
                    {
                        "path": "setups/default/s.example",
                        "target": ".example",
                        "strip_first_line": True,
                    }
                ]
            }

            saves = settings_core._plan_dotfile_saves(plan, home, root)

            self.assertEqual(len(saves), 1)
            self.assertTrue(saves[0]["changed"])
            self.assertEqual(saves[0]["content"], b".example\nimperative edit\n")

    def test_gnome_selection_update_replaces_arrays_and_preserves_other_metadata(self) -> None:
        original = """name = "fixture"

[gnome]
extensions = ["old@localhost"]
remote_extensions = [
  "old@example",
]

[software]
shims = true
"""
        updated = settings_core._updated_gnome_selection(
            original,
            ["local@localhost"],
            ["remote@example", "system@example"],
        )
        parsed = settings_core.tomllib.loads(updated)

        self.assertEqual(parsed["gnome"]["extensions"], ["local@localhost"])
        self.assertEqual(
            parsed["gnome"]["remote_extensions"],
            ["remote@example", "system@example"],
        )
        self.assertTrue(parsed["software"]["shims"])

    def test_apply_writes_locks_and_symlinks_in_fake_home(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            state = root / "state"
            home.mkdir()
            with redirect_stdout(StringIO()):
                apply_settings("default", run_scripts=False, home=home, state_dir=state)

            gitconfig = home / ".gitconfig"
            self.assertTrue(gitconfig.is_symlink())
            self.assertEqual(gitconfig.resolve(), state / "locks" / "default" / "s.git")
            self.assertNotEqual(gitconfig.resolve().read_text().splitlines()[0], ".gitconfig")

    def test_standalone_install_action_can_be_selected(self) -> None:
        from settings_core import run_install

        output = StringIO()
        with redirect_stdout(output):
            run_install("default", "enable-hibernation", dry_run=True)
        self.assertIn("-> install action enable-hibernation", output.getvalue())

    def test_rpmfusion_action_can_be_selected(self) -> None:
        from settings_core import run_install

        output = StringIO()
        with redirect_stdout(output):
            run_install("default", "enable-rpmfusion", dry_run=True)
        self.assertIn("-> install action enable-rpmfusion", output.getvalue())

    def test_install_shell_entrypoints_have_valid_syntax(self) -> None:
        scripts = [
            *sorted((ROOT / "apply" / "actions").glob("*.sh")),
            *sorted((ROOT / "install" / "actions").glob("*.sh")),
            *sorted((ROOT / "install" / "providers").glob("*.sh")),
        ]
        for script in scripts:
            with self.subTest(script=script.relative_to(ROOT)):
                subprocess.check_call(["bash", "-n", str(script)])

    def test_gnome_extension_action_installs_bundled_extension(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            home.mkdir()
            env = os.environ.copy()
            env.update(
                {
                    "HOME": str(home),
                    "SETTINGS_GNOME_EXTENSIONS": "settings-main@localhost",
                    "SETTINGS_GNOME_REMOTE_EXTENSIONS": "",
                    "SETTINGS_GNOME_EXTENSIONS_FORCE": "1",
                    "SETTINGS_GNOME_EXTENSIONS_ENABLE": "0",
                    "SETTINGS_GNOME_EXTENSIONS_GSETTINGS": "0",
                }
            )
            subprocess.check_call(
                ["bash", str(ROOT / "apply" / "actions" / "gnome-extensions.sh")],
                env=env,
                stdout=subprocess.DEVNULL,
            )

            installed = home / ".local/share/gnome-shell/extensions/settings-main@localhost"
            self.assertTrue((installed / "metadata.json").exists())
            self.assertTrue((installed / "extension.js").exists())
            self.assertTrue((installed / "stylesheet.css").exists())

    def test_gnome_extension_action_installs_remote_and_enforces_exact_enabled_set(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            fakebin = root / "bin"
            log = root / "gnome-extensions.log"
            installed_state = root / "installed"
            enabled_state = root / "enabled"
            home.mkdir()
            fakebin.mkdir()
            installed_state.write_text("extra@example\n")
            enabled_state.write_text("extra@example\n")
            fake_command = fakebin / "gnome-extensions"
            fake_command.write_text(
                """#!/usr/bin/env bash
printf '%s\\n' "$*" >>"$GNOME_EXTENSIONS_FAKE_LOG"
case "$1" in
    create)
        for arg in "$@"; do
            case "$arg" in
                --uuid=*) uuid="${arg#--uuid=}" ;;
            esac
        done
        mkdir -p "$HOME/.local/share/gnome-shell/extensions/$uuid"
        ;;
    list)
        if [[ ${2:-} == "--enabled" ]]; then
            cat "$GNOME_EXTENSIONS_ENABLED_STATE"
        else
            cat "$GNOME_EXTENSIONS_INSTALLED_STATE"
        fi
        ;;
    enable)
        grep -Fxq "$2" "$GNOME_EXTENSIONS_ENABLED_STATE" ||
            printf '%s\\n' "$2" >>"$GNOME_EXTENSIONS_ENABLED_STATE"
        ;;
    disable)
        grep -Fxv "$2" "$GNOME_EXTENSIONS_ENABLED_STATE" >"$GNOME_EXTENSIONS_ENABLED_STATE.tmp" || true
        mv "$GNOME_EXTENSIONS_ENABLED_STATE.tmp" "$GNOME_EXTENSIONS_ENABLED_STATE"
        ;;
esac
"""
            )
            fake_command.chmod(0o755)
            fake_busctl = fakebin / "busctl"
            fake_busctl.write_text(
                """#!/usr/bin/env bash
printf 'busctl %s\\n' "$*" >>"$GNOME_EXTENSIONS_FAKE_LOG"
uuid="${@: -1}"
grep -Fxq "$uuid" "$GNOME_EXTENSIONS_INSTALLED_STATE" ||
    printf '%s\\n' "$uuid" >>"$GNOME_EXTENSIONS_INSTALLED_STATE"
printf 's "successful"\\n'
"""
            )
            fake_busctl.chmod(0o755)

            env = os.environ.copy()
            env.update(
                {
                    "HOME": str(home),
                    "PATH": f"{fakebin}:{env.get('PATH', '')}",
                    "GNOME_EXTENSIONS_FAKE_LOG": str(log),
                    "GNOME_EXTENSIONS_INSTALLED_STATE": str(installed_state),
                    "GNOME_EXTENSIONS_ENABLED_STATE": str(enabled_state),
                    "SETTINGS_GNOME_EXTENSIONS": "settings-main@localhost",
                    "SETTINGS_GNOME_REMOTE_EXTENSIONS": "remote@example",
                    "SETTINGS_GNOME_EXTENSIONS_FORCE": "1",
                    "SETTINGS_GNOME_EXTENSIONS_ENABLE": "1",
                    "SETTINGS_GNOME_EXTENSIONS_GSETTINGS": "0",
                }
            )

            subprocess.check_call(
                ["bash", str(ROOT / "apply" / "actions" / "gnome-extensions.sh")],
                env=env,
                stdout=subprocess.DEVNULL,
            )

            installed = home / ".local/share/gnome-shell/extensions/settings-main@localhost"
            self.assertTrue((installed / "metadata.json").exists())
            command_log = log.read_text()
            self.assertIn("create", command_log)
            self.assertIn("busctl", command_log)
            self.assertIn("ReloadExtension", command_log)
            self.assertIn("remote@example", command_log)
            self.assertIn("enable settings-main@localhost", command_log)
            self.assertIn("enable remote@example", command_log)
            self.assertIn("disable extra@example", command_log)
            self.assertEqual(
                enabled_state.read_text().splitlines(),
                ["settings-main@localhost", "remote@example"],
            )

    def test_bundled_gnome_extension_metadata_matches_directory(self) -> None:
        metadata_files = sorted((ROOT / "gnome-extensions").glob("*/metadata.json"))
        self.assertTrue(metadata_files)
        for metadata_file in metadata_files:
            with self.subTest(extension=metadata_file.parent.name):
                metadata = json.loads(metadata_file.read_text())
                self.assertEqual(metadata["uuid"], metadata_file.parent.name)

    def test_software_shim_installs_and_forwards_arguments(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            home = root / "home"
            recipes = root / "recipes"
            state = root / "state"
            home.mkdir()
            recipes.mkdir()
            (recipes / "demo.sh").write_text(
                """recipe_bin() {
    echo demo
}

recipe_install() {
    mkdir -p "$HOME/.local/bin"
    cat >"$HOME/.local/bin/demo" <<'EOF'
#!/usr/bin/env bash
printf 'demo:%s\\n' "$*"
EOF
    chmod +x "$HOME/.local/bin/demo"
}
"""
            )

            env = os.environ.copy()
            env.update(
                {
                    "HOME": str(home),
                    "PATH": f"{home / '.local/bin'}:{env.get('PATH', '')}",
                    "SETTINGS_SOFTWARE_ASSUME_ONLINE": "1",
                    "SETTINGS_SOFTWARE_RECIPES_DIR": str(recipes),
                    "SETTINGS_STATE_DIR": str(state),
                }
            )

            subprocess.check_call([str(ROOT / "bin" / "settings-software"), "setup-shims"], env=env)
            shim = home / ".local" / "bin" / "demo"
            self.assertTrue(shim.is_symlink())

            output = subprocess.check_output([str(shim), "one", "two"], env=env, text=True)
            self.assertEqual(output, "demo:one two\n")
            self.assertFalse(shim.is_symlink())
            self.assertIn("demo", (state / "software" / "installed").read_text().splitlines())

    def test_migrated_setups_validate(self) -> None:
        for setup in ("default", "gnome", "silverblue", "bluefin", "hyprland", "mate-i3"):
            self.assertEqual(validate_setup(setup), [])


if __name__ == "__main__":
    unittest.main()
