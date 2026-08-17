from __future__ import annotations

import json
import os
import re
import shlex
import shutil
import subprocess
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # pragma: no cover - fallback for older Python.
    tomllib = None


ROOT = Path(__file__).resolve().parents[1]
SETUPS_DIR = ROOT / "setups"
NUMBERED_SCRIPT_RE = re.compile(r"^([0-9][0-9])-[A-Za-z0-9][A-Za-z0-9._-]*\.sh$")


class SettingsError(RuntimeError):
    pass


def _parse_simple_value(value: str) -> Any:
    value = value.strip()
    if value == "true":
        return True
    if value == "false":
        return False
    if value.startswith('"') and value.endswith('"'):
        return value[1:-1]
    if value.startswith("[") and value.endswith("]"):
        body = value[1:-1].strip()
        if not body:
            return []
        items = []
        for item in body.split(","):
            item = item.strip()
            if item.startswith('"') and item.endswith('"'):
                item = item[1:-1]
            items.append(item)
        return items
    return value


def _parse_simple_toml(text: str) -> dict[str, Any]:
    data: dict[str, Any] = {}
    current = data
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            current = data.setdefault(line[1:-1], {})
            continue
        key, sep, value = line.partition("=")
        if not sep:
            raise SettingsError(f"invalid metadata line: {raw_line}")
        current[key.strip()] = _parse_simple_value(value)
    return data


def load_toml(path: Path) -> dict[str, Any]:
    text = path.read_text()
    if tomllib is not None:
        return tomllib.loads(text)
    return _parse_simple_toml(text)


def setup_names() -> list[str]:
    if not SETUPS_DIR.exists():
        return []
    return sorted(path.name for path in SETUPS_DIR.iterdir() if path.is_dir())


def setup_dir(name: str) -> Path:
    return SETUPS_DIR / name


def load_setup(name: str) -> dict[str, Any]:
    directory = setup_dir(name)
    if not directory.is_dir():
        raise SettingsError(f"setup does not exist: {name}")
    metadata_path = directory / "setup.toml"
    if not metadata_path.exists():
        raise SettingsError(f"setup is missing setup.toml: {name}")
    metadata = load_toml(metadata_path)
    metadata.setdefault("name", name)
    metadata.setdefault("inherits", [])
    metadata.setdefault("install", {})
    metadata.setdefault("software", {})
    metadata.setdefault("gnome", {})
    metadata["install"].setdefault("groups", [])
    metadata["install"].setdefault("actions", [])
    metadata["software"].setdefault("shims", False)
    metadata["software"].setdefault("targets", [])
    metadata["gnome"].setdefault("extensions", [])
    metadata["gnome"].setdefault("remote_extensions", [])
    return metadata


def resolve_lineage(name: str) -> list[str]:
    resolved: list[str] = []
    visiting: list[str] = []
    visited: set[str] = set()

    def visit(setup: str) -> None:
        if setup in visiting:
            cycle = " -> ".join([*visiting, setup])
            raise SettingsError(f"setup inheritance cycle: {cycle}")
        if setup in visited:
            return
        metadata = load_setup(setup)
        visiting.append(setup)
        for parent in metadata.get("inherits", []):
            visit(parent)
        visiting.pop()
        visited.add(setup)
        resolved.append(setup)

    visit(name)
    return resolved


def _dedupe_extend(target: list[str], values: list[str]) -> None:
    for value in values:
        if value not in target:
            target.append(value)


def parse_setting(path: Path, setup: str) -> dict[str, Any]:
    with path.open() as handle:
        first_line = handle.readline().rstrip("\n")
    if not first_line:
        raise SettingsError(f"setting has empty first line: {path}")
    fields = first_line.strip().split(maxsplit=1)
    target = fields[1] if len(fields) == 2 else first_line.strip()
    if not target:
        raise SettingsError(f"setting has empty target path: {path}")
    strip_first_line = len(fields) == 1
    try:
        display_path = str(path.relative_to(ROOT))
    except ValueError:
        display_path = str(path)
    return {
        "name": path.name,
        "setup": setup,
        "path": display_path,
        "target": target,
        "strip_first_line": strip_first_line,
    }


def parse_script(path: Path, setup: str, kind: str = "lifecycle") -> dict[str, Any]:
    lines = path.read_text(errors="replace").splitlines()
    shebang = lines[0].strip() if lines else ""
    condition_line = lines[1].strip() if len(lines) > 1 else ""
    condition = condition_line[1:].strip() if condition_line.startswith("#") else condition_line
    number_match = NUMBERED_SCRIPT_RE.match(path.name)
    number = int(number_match.group(1)) if number_match else None
    phase = None
    if kind == "lifecycle" and number is not None:
        phase = "pre" if number < 50 else "post"
    interpreter = shebang[2:].strip() if shebang.startswith("#!") else ""
    return {
        "name": path.name,
        "setup": setup,
        "path": str(path.relative_to(ROOT)),
        "kind": kind,
        "number": number,
        "phase": phase,
        "shebang": shebang,
        "interpreter": interpreter,
        "condition": condition,
    }


def _action_path(action: str) -> Path:
    return ROOT / "install" / "actions" / f"{action}.sh"


def _apply_action_path(action: str) -> Path:
    return ROOT / "apply" / "actions" / f"{action}.sh"


def _group_path(group: str) -> Path | None:
    groups_dir = ROOT / "install" / "groups"
    for suffix in (".toml", ".txt", ".sh", ""):
        path = groups_dir / f"{group}{suffix}"
        if path.exists():
            return path
    return None


def _group_exists(group: str) -> bool:
    return _group_path(group) is not None


def load_group(group: str) -> dict[str, Any]:
    path = _group_path(group)
    if path is None:
        raise SettingsError(f"install group does not exist: {group}")

    data: dict[str, Any]
    if path.suffix == ".toml":
        data = load_toml(path)
    elif path.suffix == ".txt":
        packages = []
        for raw_line in path.read_text().splitlines():
            line = raw_line.strip()
            if line and not line.startswith("#"):
                packages.append(line)
        data = {"packages": packages}
    else:
        data = {"legacy_script": True}

    data.setdefault("description", "")
    data.setdefault("providers", ["dnf", "rpm-ostree"])
    data.setdefault("packages", [])
    data.setdefault("remove", [])
    data.setdefault("flatpaks", [])
    data.setdefault("kargs", [])
    data.setdefault("classic", [])
    return {
        "name": group,
        "path": str(path.relative_to(ROOT)),
        "description": data["description"],
        "providers": data["providers"],
        "packages": data["packages"],
        "remove": data["remove"],
        "flatpaks": data["flatpaks"],
        "kargs": data["kargs"],
        "classic": data["classic"],
        "legacy_script": bool(data.get("legacy_script", False)),
    }


def detect_package_provider() -> str:
    if shutil.which("rpm-ostree") and Path("/run/ostree-booted").exists():
        return "rpm-ostree"
    if shutil.which("dnf5") or shutil.which("dnf"):
        return "dnf"
    return "dnf"


def _provider_path(provider: str) -> Path:
    return ROOT / "install" / "providers" / f"{provider}.sh"


def _command_entry(provider: str, operation: str, args: list[str], group: str) -> dict[str, Any] | None:
    if not args:
        return None
    path = _provider_path(provider)
    if not path.exists():
        raise SettingsError(f"install provider does not exist: {provider}")
    return {
        "group": group,
        "provider": provider,
        "operation": operation,
        "argv": [str(path), operation, *args],
    }


def build_install_commands(
    plan: dict[str, Any],
    provider: str = "auto",
    selected: str = "all",
) -> list[dict[str, Any]]:
    package_provider = detect_package_provider() if provider == "auto" else provider
    commands: list[dict[str, Any]] = []
    seen: dict[tuple[str, str], set[str]] = {}

    def add(provider_name: str, operation: str, args: list[str], group: str) -> None:
        key = (provider_name, operation)
        seen.setdefault(key, set())
        filtered = []
        for arg in args:
            if arg not in seen[key]:
                seen[key].add(arg)
                filtered.append(arg)
        entry = _command_entry(provider_name, operation, filtered, group)
        if entry is not None:
            commands.append(entry)

    for group in plan["install"]["group_details"]:
        if selected not in ("all", group["name"]):
            continue
        if group["legacy_script"]:
            continue
        providers = group["providers"]
        group_provider = package_provider
        if package_provider not in providers and len(providers) == 1:
            group_provider = providers[0]
        if group["packages"] or group["remove"] or group["kargs"] or group["classic"]:
            if group_provider not in providers:
                raise SettingsError(
                    f"group {group['name']} does not support provider {package_provider}"
                )
        if group["classic"] and group_provider != "snap":
            raise SettingsError(f"group {group['name']} classic packages require snap provider")
        add(group_provider, "install", group["packages"], group["name"])
        add(group_provider, "install-classic", group["classic"], group["name"])
        add(group_provider, "remove", group["remove"], group["name"])
        if group["kargs"]:
            if group_provider != "rpm-ostree":
                raise SettingsError(f"group {group['name']} kargs require rpm-ostree provider")
            add("rpm-ostree", "kargs", group["kargs"], group["name"])
        add("flatpak", "install", group["flatpaks"], group["name"])

    return commands


def build_plan(name: str) -> dict[str, Any]:
    lineage = resolve_lineage(name)
    settings: dict[str, dict[str, Any]] = {}
    scripts: dict[str, dict[str, Any]] = {}
    hooks: dict[str, dict[str, Any]] = {}
    install_groups: list[str] = []
    install_actions: list[str] = []
    software_targets: list[str] = []
    software_shims = False
    gnome_extensions: list[str] = []
    gnome_remote_extensions: list[str] = []

    for setup in lineage:
        directory = setup_dir(setup)
        metadata = load_setup(setup)
        _dedupe_extend(install_groups, metadata["install"].get("groups", []))
        _dedupe_extend(install_actions, metadata["install"].get("actions", []))
        _dedupe_extend(software_targets, metadata["software"].get("targets", []))
        _dedupe_extend(gnome_extensions, metadata["gnome"].get("extensions", []))
        _dedupe_extend(gnome_remote_extensions, metadata["gnome"].get("remote_extensions", []))
        software_shims = software_shims or bool(metadata["software"].get("shims", False))

        for path in sorted(directory.glob("s.*")):
            settings[path.name] = parse_setting(path, setup)
        for path in sorted(directory.glob("[0-9][0-9]-*.sh")):
            scripts[path.name] = parse_script(path, setup)
        hooks_dir = directory / "install.d"
        if hooks_dir.is_dir():
            for path in sorted(hooks_dir.glob("*.sh")):
                hooks[path.name] = parse_script(path, setup, "install-hook")

    target_to_name: dict[str, str] = {}
    for setting in settings.values():
        existing = target_to_name.get(setting["target"])
        if existing and existing != setting["name"]:
            raise SettingsError(
                f"settings target collision: {existing} and {setting['name']} both target {setting['target']}"
            )
        target_to_name[setting["target"]] = setting["name"]

    scripts_by_phase = {"pre": [], "post": []}
    for script in sorted(scripts.values(), key=lambda item: item["name"]):
        scripts_by_phase[script["phase"]].append(script)

    actions = [
        {
            "name": action,
            "path": str(_action_path(action).relative_to(ROOT)),
        }
        for action in install_actions
    ]
    group_details = [load_group(group) for group in install_groups]

    return {
        "setup": name,
        "lineage": lineage,
        "settings": sorted(settings.values(), key=lambda item: item["name"]),
        "scripts": scripts_by_phase,
        "install": {
            "groups": install_groups,
            "group_details": group_details,
            "actions": actions,
            "hooks": sorted(hooks.values(), key=lambda item: item["name"]),
        },
        "software": {
            "shims": software_shims,
            "targets": software_targets,
        },
        "gnome": {
            "extensions": gnome_extensions,
            "remote_extensions": gnome_remote_extensions,
        },
    }


def plan_json(name: str) -> str:
    return json.dumps(build_plan(name), indent=2, sort_keys=True)


def validate_setup(name: str) -> list[str]:
    errors: list[str] = []
    try:
        lineage = resolve_lineage(name)
    except SettingsError as exc:
        return [str(exc)]

    for setup in lineage:
        try:
            metadata = load_setup(setup)
        except SettingsError as exc:
            errors.append(str(exc))
            continue
        if metadata.get("name") != setup:
            errors.append(f"setup name does not match folder: {setup}")

    try:
        plan = build_plan(name)
    except SettingsError as exc:
        errors.append(str(exc))
        return errors

    for phase in ("pre", "post"):
        for script in plan["scripts"][phase]:
            if not script["shebang"].startswith("#!"):
                errors.append(f"lifecycle script missing shebang: {script['path']}")
            if not script["condition"]:
                errors.append(f"lifecycle script missing condition line: {script['path']}")

    for setup in lineage:
        for path in sorted(setup_dir(setup).glob("[0-9][0-9]*.sh")):
            if not NUMBERED_SCRIPT_RE.match(path.name):
                errors.append(f"lifecycle script must be named NN-name.sh: {path.relative_to(ROOT)}")

    for group in plan["install"]["groups"]:
        if not _group_exists(group):
            errors.append(f"install group does not exist: {group}")
    for group in plan["install"].get("group_details", []):
        for provider in group["providers"]:
            if provider not in ("dnf", "rpm-ostree", "brew", "snap"):
                errors.append(f"install group {group['name']} has unknown provider: {provider}")
            elif not _provider_path(provider).exists():
                errors.append(f"install provider does not exist: {provider}")
        if group["flatpaks"] and not _provider_path("flatpak").exists():
            errors.append("install provider does not exist: flatpak")

    for action in plan["install"]["actions"]:
        if not (ROOT / action["path"]).exists():
            errors.append(f"install action does not exist: {action['name']}")

    for hook in plan["install"]["hooks"]:
        if not NUMBERED_SCRIPT_RE.match(hook["name"]):
            errors.append(f"install hook must be named NN-name.sh: {hook['path']}")
        if not hook["shebang"].startswith("#!"):
            errors.append(f"install hook missing shebang: {hook['path']}")

    if plan["gnome"]["extensions"] or plan["gnome"]["remote_extensions"]:
        if not _apply_action_path("gnome-extensions").exists():
            errors.append("apply action does not exist: gnome-extensions")
    for extension in plan["gnome"]["extensions"]:
        extension_dir = ROOT / "gnome-extensions" / extension
        metadata_path = extension_dir / "metadata.json"
        if not extension_dir.is_dir():
            errors.append(f"gnome extension does not exist: {extension}")
            continue
        if not metadata_path.exists():
            errors.append(f"gnome extension is missing metadata.json: {extension}")
            continue
        try:
            metadata = json.loads(metadata_path.read_text())
        except json.JSONDecodeError as exc:
            errors.append(f"gnome extension metadata is invalid JSON: {extension}: {exc}")
            continue
        if metadata.get("uuid") != extension:
            errors.append(f"gnome extension uuid does not match folder: {extension}")

    recipe_dir = ROOT / "software" / "recipes"
    for target in plan["software"]["targets"]:
        if not any(target in path.stem.split() or path.stem == target for path in recipe_dir.glob("*.sh")):
            errors.append(f"software target has no obvious recipe: {target}")

    return errors


def _condition_passes(condition: str) -> bool:
    if not condition:
        return False
    return subprocess.run(
        ["bash", "-c", condition],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    ).returncode == 0


def _run_script(script: dict[str, Any]) -> None:
    path = ROOT / script["path"]
    if not _condition_passes(script["condition"]):
        print(f"-> skipping {script['name']}")
        return
    argv = [*shlex.split(script["interpreter"]), str(path)]
    print(f"-> executing {script['name']}")
    subprocess.check_call(argv)


def _run_gnome_extensions_action(plan: dict[str, Any], home: Path) -> None:
    extensions = plan["gnome"]["extensions"]
    remote_extensions = plan["gnome"]["remote_extensions"]
    if "gnome" not in plan["lineage"] and not extensions and not remote_extensions:
        return
    path = _apply_action_path("gnome-extensions")
    if not path.exists():
        raise SettingsError("apply action does not exist: gnome-extensions")

    env = os.environ.copy()
    env["HOME"] = str(home)
    env["SETTINGS_GNOME_EXTENSIONS"] = "\n".join(extensions)
    env["SETTINGS_GNOME_REMOTE_EXTENSIONS"] = "\n".join(remote_extensions)
    env["SETTINGS_GNOME_EXTENSIONS_FORCE"] = "1"
    print("-> applying gnome extensions")
    subprocess.check_call(["bash", str(path)], env=env)


def _saved_setting_bytes(setting: dict[str, Any], source: bytes, installed: bytes) -> bytes:
    if not setting["strip_first_line"]:
        return installed

    marker_lines = source.splitlines(keepends=True)
    if not marker_lines:
        raise SettingsError(f"setting has no target marker: {setting['path']}")
    marker = marker_lines[0]
    if not marker.endswith((b"\n", b"\r")):
        marker += b"\n"
    return marker + installed


def _plan_dotfile_saves(
    plan: dict[str, Any],
    home: Path,
    root: Path = ROOT,
) -> list[dict[str, Any]]:
    saves: list[dict[str, Any]] = []
    missing: list[str] = []

    for setting in plan["settings"]:
        source = root / setting["path"]
        target = home / setting["target"]
        if not target.exists() or not target.is_file():
            missing.append(f"~/{setting['target']}")
            continue

        source_bytes = source.read_bytes()
        saved_bytes = _saved_setting_bytes(setting, source_bytes, target.read_bytes())
        saves.append(
            {
                "source": source,
                "target": target,
                "display_source": setting["path"],
                "display_target": f"~/{setting['target']}",
                "content": saved_bytes,
                "changed": saved_bytes != source_bytes,
            }
        )

    if missing:
        raise SettingsError("installed settings are missing: " + ", ".join(missing))
    return saves


def _enabled_gnome_extensions() -> list[str]:
    if shutil.which("gnome-extensions") is None:
        raise SettingsError("gnome-extensions command is required to save extension state")

    result = subprocess.run(
        ["gnome-extensions", "list", "--enabled"],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        detail = result.stderr.strip() or f"exit status {result.returncode}"
        raise SettingsError(f"could not read enabled GNOME extensions: {detail}")
    return list(dict.fromkeys(line.strip() for line in result.stdout.splitlines() if line.strip()))


def _format_toml_array(key: str, values: list[str]) -> list[str]:
    if not values:
        return [f"{key} = []"]
    return [
        f"{key} = [",
        *(f"  {json.dumps(value, ensure_ascii=False)}," for value in values),
        "]",
    ]


def _toml_assignment_end(lines: list[str], start: int) -> int:
    _, _, value = lines[start].partition("=")
    balance = value.count("[") - value.count("]")
    index = start + 1
    while balance > 0 and index < len(lines):
        balance += lines[index].count("[") - lines[index].count("]")
        index += 1
    return index


def _updated_gnome_selection(
    text: str,
    bundled: list[str],
    remote: list[str],
) -> str:
    lines = text.splitlines()
    section_start: int | None = None
    section_end = len(lines)

    for index, line in enumerate(lines):
        match = re.match(r"^\s*\[([^]]+)]\s*(?:#.*)?$", line)
        if not match:
            continue
        if match.group(1).strip() == "gnome":
            section_start = index
            continue
        if section_start is not None:
            section_end = index
            break

    if section_start is None:
        if lines and lines[-1].strip():
            lines.append("")
        lines.append("[gnome]")
        section_start = len(lines) - 1
        section_end = len(lines)

    body = lines[section_start + 1 : section_end]
    preserved: list[str] = []
    insertion_index: int | None = None
    index = 0
    while index < len(body):
        match = re.match(r"^\s*(extensions|remote_extensions)\s*=", body[index])
        if not match:
            preserved.append(body[index])
            index += 1
            continue
        if insertion_index is None:
            insertion_index = len(preserved)
        index = _toml_assignment_end(body, index)

    if insertion_index is None:
        while preserved and not preserved[-1].strip():
            preserved.pop()
        insertion_index = len(preserved)

    selection = [
        *_format_toml_array("extensions", bundled),
        *_format_toml_array("remote_extensions", remote),
    ]
    updated_body = [
        *preserved[:insertion_index],
        *selection,
        *preserved[insertion_index:],
    ]
    lines[section_start + 1 : section_end] = updated_body
    updated = "\n".join(lines) + "\n"

    if tomllib is not None:
        try:
            tomllib.loads(updated)
        except tomllib.TOMLDecodeError as exc:
            raise SettingsError(f"generated setup metadata is invalid TOML: {exc}") from exc
    return updated


def save_settings(
    name: str,
    home: Path | None = None,
    enabled_extensions: list[str] | None = None,
    dry_run: bool = False,
) -> None:
    plan = build_plan(name)
    if home is None:
        home = Path(os.environ.get("HOME", str(Path.home())))

    dotfile_saves = _plan_dotfile_saves(plan, home)
    setup_metadata_path: Path | None = None
    setup_metadata_text: str | None = None
    metadata_changed = False

    if "gnome" in plan["lineage"]:
        if enabled_extensions is None:
            enabled_extensions = _enabled_gnome_extensions()
        enabled_extensions = list(dict.fromkeys(enabled_extensions))
        bundled = [
            uuid for uuid in enabled_extensions if (ROOT / "gnome-extensions" / uuid).is_dir()
        ]
        remote = [uuid for uuid in enabled_extensions if uuid not in bundled]
        setup_metadata_path = setup_dir(name) / "setup.toml"
        original_metadata = setup_metadata_path.read_text()
        current_metadata = load_toml(setup_metadata_path)
        current_gnome = current_metadata.get("gnome", {})
        if (
            current_gnome.get("extensions", []) == bundled
            and current_gnome.get("remote_extensions", []) == remote
        ):
            setup_metadata_text = original_metadata
        else:
            setup_metadata_text = _updated_gnome_selection(original_metadata, bundled, remote)
        metadata_changed = setup_metadata_text != original_metadata

    changed_dotfiles = [save for save in dotfile_saves if save["changed"]]
    action = "would save" if dry_run else "saved"
    for save in changed_dotfiles:
        if not dry_run:
            save["source"].write_bytes(save["content"])
        print(f"-> {action} {save['display_target']} to {save['display_source']}")

    if metadata_changed and setup_metadata_path is not None and setup_metadata_text is not None:
        if not dry_run:
            setup_metadata_path.write_text(setup_metadata_text)
        print(f"-> {action} enabled GNOME extensions to {setup_metadata_path.relative_to(ROOT)}")

    suffix = " (dry run)" if dry_run else ""
    extension_status = "changed" if metadata_changed else "unchanged"
    if setup_metadata_path is None:
        extension_status = "not applicable"
    summary_action = "would save" if dry_run else "saved"
    print(
        f"{summary_action} {len(changed_dotfiles)} of {len(dotfile_saves)} dotfiles; "
        f"GNOME extensions {extension_status}{suffix}"
    )


def apply_settings(
    name: str,
    run_scripts: bool = True,
    home: Path | None = None,
    state_dir: Path | None = None,
) -> None:
    plan = build_plan(name)
    if state_dir is None:
        state_dir = Path(os.environ.get("SETTINGS_STATE_DIR", ROOT / ".state"))
    lock_dir = state_dir / "locks" / name
    lock_dir.mkdir(parents=True, exist_ok=True)
    if home is None:
        home = Path(os.environ.get("HOME", str(Path.home())))

    if run_scripts:
        for script in plan["scripts"]["pre"]:
            _run_script(script)
        _run_gnome_extensions_action(plan, home)

    for setting in plan["settings"]:
        source = ROOT / setting["path"]
        lock = lock_dir / setting["name"]
        if setting["strip_first_line"]:
            lines = source.read_text().splitlines(keepends=True)
            lock.write_text("".join(lines[1:]))
        else:
            shutil.copyfile(source, lock)
        target = home / setting["target"]
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            if target.is_dir() and not target.is_symlink():
                raise SettingsError(f"target is a directory, refusing to replace: {target}")
            target.unlink()
        target.symlink_to(lock)
        print(f"-> installed {setting['name']} to ~/{setting['target']}")

    if run_scripts:
        for script in plan["scripts"]["post"]:
            _run_script(script)


def _print_command(argv: list[str]) -> None:
    print("+ " + " ".join(shlex.quote(arg) for arg in argv))


def _run_action(path: Path, dry_run: bool) -> None:
    if dry_run:
        print(f"+ SETTINGS_DRY_RUN=1 bash {shlex.quote(str(path))}")
        return
    subprocess.check_call(["bash", str(path)])


def run_install(name: str, selected: str = "all", dry_run: bool = False, provider: str = "auto") -> None:
    plan = build_plan(name)
    actions = plan["install"]["actions"]
    hooks = plan["install"]["hooks"]
    commands = build_install_commands(plan, provider, selected)
    matched = False

    for command in commands:
        matched = True
        print(f"-> install group {command['group']} ({command['provider']} {command['operation']})")
        if dry_run:
            _print_command(command["argv"])
        else:
            subprocess.check_call(command["argv"])

    for action in actions:
        if selected not in ("all", action["name"]):
            continue
        matched = True
        print(f"-> install action {action['name']}")
        _run_action(ROOT / action["path"], dry_run)

    for hook in hooks:
        if selected not in ("all", hook["name"]):
            continue
        matched = True
        print(f"-> install hook {hook['name']}")
        _run_action(ROOT / hook["path"], dry_run)

    if selected != "all" and not matched:
        if _group_exists(selected):
            one_off_plan = {"install": {"group_details": [load_group(selected)]}}
            for command in build_install_commands(one_off_plan, provider, selected):
                matched = True
                print(f"-> install group {command['group']} ({command['provider']} {command['operation']})")
                if dry_run:
                    _print_command(command["argv"])
                else:
                    subprocess.check_call(command["argv"])
        elif _action_path(selected).exists():
            matched = True
            print(f"-> install action {selected}")
            _run_action(_action_path(selected), dry_run)

    if selected != "all" and not matched:
        raise SettingsError(f"no install group, action, or hook matched: {selected}")
