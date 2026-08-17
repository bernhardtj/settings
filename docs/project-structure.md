# Project Structure Design

This repository is intended to become a multi-setup dotfiles system. It should
keep the useful simplicity of the old `apply` script while making setup
inheritance, installation recipes, and on-demand software installs explicit.

The core design rule is:

> Setup folders describe what should be applied. Root-level infrastructure
> describes how it is applied.

## Goals

- Support multiple dotfile configurations in parallel.
- Allow setups to inherit from other setups, starting from the root setup named
  `default`.
- Keep setup folders fairly flat and close to the old reference layout.
- Move common scripts, installation machinery, and software-install helpers out
  of individual setups.
- Use Just as the primary command surface for setup, installation, and
  on-demand software work.
- Keep the bootstrap path conservative: bash, python, curl, and standard Fedora
  tools should be enough to get the repository into a usable state.

## Proposed Top-Level Layout

```text
.
|-- Justfile
|-- start-here.md
|-- docs/
|   `-- project-structure.md
|-- bin/
|   |-- settings
|   |-- settings-apply
|   |-- settings-setup
|   `-- settings-software
|-- lib/
|   |-- apply.sh
|   |-- install.sh
|   |-- setup-resolver.py
|   `-- software.sh
|-- apply/
|   `-- actions/
|-- gnome-extensions/
|   |-- settings-main@localhost/
|   `-- settings-notification-ticker@localhost/
|-- install/
|   |-- actions/
|   |-- groups/
|   |-- hosts/
|   `-- providers/
|-- software/
|   |-- Justfile
|   |-- recipes/
|   `-- shims/
|-- setups/
|   |-- default/
|   |-- gnome/
|   |-- silverblue/
|   |-- bluefin/
|   |-- hyprland/
|   `-- mate-i3/
`-- .state/
    |-- locks/
    `-- software/
```

### `Justfile`

The root `Justfile` is the main human-facing interface. It should be small and
mostly dispatch into scripts under `bin/` and `lib/`.

Expected root recipes:

```just
list:
    bin/settings-setup list

lineage setup="default":
    bin/settings-setup lineage {{setup}}

plan setup="default":
    bin/settings-apply --plan {{setup}}

apply setup="default":
    bin/settings-apply {{setup}}

apply-settings-only setup="default":
    bin/settings-apply {{setup}} --no-scripts

save setup="default":
    bin/settings-save {{setup}}

save-dry setup="default":
    bin/settings-save {{setup}} --dry-run

install setup="default" group="all":
    bin/settings install {{setup}} {{group}}

install-dry setup="default" group="all" provider="auto":
    bin/settings-install {{setup}} {{group}} --dry-run --provider {{provider}}

software target:
    bin/settings-software install {{target}}

software-setup:
    bin/settings-software setup-shims

validate setup="default":
    bin/settings-setup validate {{setup}}

validate-all:
    for setup in $(bin/settings-setup list); do bin/settings-setup validate "$setup"; done

ci:
    just validate-all
    just test

ci-podman:
    podman run --rm -it -v "$PWD:/workspace:Z" -w /workspace fedora:latest bash -lc 'dnf install -y python3 bash just ShellCheck && just ci'
```

Just should orchestrate commands, not hold large bodies of shell logic. Keeping
implementation in `bin/` and `lib/` makes bootstrap and testing easier.

### `bin/`

`bin/` contains executable entry points. These are the commands Just calls and
the commands a user can run directly when Just is unavailable.

- `settings`: convenience command that dispatches to the other entry points.
- `settings-apply`: resolves setup inheritance, runs lifecycle scripts, and
  applies dotfiles.
- `settings-setup`: lists setups, prints inheritance chains, validates setup
  metadata, and explains merge results.
- `settings-software`: handles on-demand CLI software installation and shim
  creation.

These commands should use only root-level libraries and setup data. They should
not duplicate helper logic inside setup folders.

### `lib/`

`lib/` contains reusable implementation details.

- `apply.sh`: old `apply` behavior, generalized for inherited setup folders.
- `install.sh`: shared install helpers for Fedora, rpm-ostree, Flatpak, and
  other providers.
- `setup-resolver.py`: setup metadata parser and inheritance resolver.
- `software.sh`: shared functions for downloads, GitHub releases, Fedora RPM
  extraction, Mason installs, permission repair, and shim management.

Python is appropriate for metadata parsing and merge planning. Shell remains
appropriate for system mutation because most commands are native shell commands
already.

### `install/`

`install/` holds reusable installation data and provider helpers. This replaces
the old model where setup scripts lived in an `install/` folder inside the
reference repo.

Suggested subdirectories:

- `install/actions/`: named, idempotent install actions for loose commands or
  small scripts that do not fit cleanly into a package group.
- `install/groups/`: package group definitions, such as `fedora-deps`,
  `bluefin-deps`, `fedora-tools`, `virt`, `rpm-build`, and `openh264`.
- `install/hosts/`: host or hardware detection snippets, such as CPU-specific
  kernel arguments or driver package selections.
- `install/providers/`: provider-specific implementation for `dnf`,
  `rpm-ostree`, `flatpak`, `brew`, `snap`, and direct downloads.

Setups should select installation groups and named actions. The provider
helpers should decide how to apply package groups on the current system.

### `software/`

`software/` is global infrastructure for on-demand CLI tools. It replaces the
old `software-mono.sh` plus `software/*.sh` behavior.

Suggested layout:

```text
software/
|-- Justfile
|-- recipes/
|   |-- gh.sh
|   |-- shfmt.sh
|   `-- uv.sh
`-- shims/
    `-- README.md
```

The Just interface should expose:

- `just -f software/Justfile list`
- `just -f software/Justfile install gh`
- `just -f software/Justfile recipe gh`
- `just -f software/Justfile setup-shims`
- `just -f software/Justfile update-installed`

The recipe body can remain shell-based at first. That preserves the existing
`recipe_bin` and `recipe_install` pattern while making Just the public
interface.

The shim behavior should remain:

1. `settings-software setup-shims` creates links in `~/.local/bin`.
2. A linked command, such as `gh`, triggers installation on first use.
3. The real binary replaces or shadows the shim after installation.
4. The shim immediately re-executes the installed binary with the original
   command-line arguments.
5. Installed targets are recorded in `.state/software/installed` or
   `~/.local/state/settings/software/installed`.

### `.state/`

`.state/` is generated and should not be tracked. It replaces the old `.lock`
directory as the place where rendered dotfiles and software state live.

Expected contents:

- `.state/locks/<setup>/<setting-name>`: rendered setting files with install
  path comments removed when needed.
- `.state/software/installed`: list of software targets intentionally installed.
- `.state/logs/`: optional command logs for debugging.

If the repository should stay clean after applying settings, this state can be
moved to `~/.local/state/settings/` instead. The important rule is that setup
folders remain source-only.

## Setup Folder Layout

Each setup lives under `setups/<setup-name>/`.

```text
setups/<setup-name>/
|-- setup.toml
|-- .Justfile
|-- README.md
|-- install.d/
|   |-- 20-add-copr.sh
|   `-- 60-configure-service.sh
|-- 15-gsettings-gnome.sh
|-- 25-desktop-state.sh
|-- 65-editor.sh
|-- 80-software.sh
|-- s.aliases.sh
|-- s.bash
|-- s.git
|-- s.kitty
`-- s.zsh
```

The setup directory should stay flat for normal files:

- `s.*` files are dotfiles/settings.
- `[0-9][0-9]-*.sh` files are lifecycle scripts.
- `.Justfile` contains setup-local install recipes or recipe aliases.
- `install.d/*.sh` contains setup-local install hooks for one-off commands.
- `setup.toml` describes inheritance and setup metadata.
- `README.md` is optional human context for the setup.

Nested folders are allowed only when they remove real friction, such as large
assets, generated templates, setup-local install hooks, or multi-file resources
that cannot reasonably be represented as a single `s.*` file.

## Setup Metadata

Each setup should include `setup.toml`.

Example:

```toml
name = "bluefin"
description = "Daily Bluefin GNOME workstation setup"
inherits = ["gnome"]

[install]
groups = ["bluefin-deps"]
actions = ["enable-flathub", "set-zsh-shell"]

[software]
shims = true
targets = ["gh", "uv", "shfmt", "shellcheck"]

[gnome]
extensions = ["settings-main@localhost"]
remote_extensions = ["dash-to-dock@micxgx.gmail.com"]
```

Rules:

- `default` is the root setup and should not inherit from another setup.
- Every other setup should declare exactly one parent in `inherits` unless
  multiple inheritance is deliberately introduced later.
- Setup names should match their folder names.
- Install groups should refer to root-level definitions under `install/groups/`.
- Install actions should refer to root-level scripts under `install/actions/`.
- GNOME extension UUIDs should refer to bundled directories under
  `gnome-extensions/`; remote extension UUIDs are installed through GNOME
  Shell's extension service.
- Setup metadata should describe intent; scripts should perform actions.

### GNOME Extensions

Bundled GNOME Shell extensions live at the repository root under
`gnome-extensions/<uuid>/`. Each bundled extension should look like a normal
GNOME Shell extension directory, with at least `metadata.json` and
`extension.js`; optional files such as `stylesheet.css` and `schemas/*.xml`
belong beside them.

Setups select bundled and remote extensions in `setup.toml`:

```toml
[gnome]
extensions = [
  "settings-main@localhost",
  "settings-notification-ticker@localhost",
]
remote_extensions = [
  "panel-workspace-scroll@polymeilex.github.io",
  "dash-to-dock@micxgx.gmail.com",
]
```

During `settings apply`, the apply engine runs
`apply/actions/gnome-extensions.sh` after pre-scripts. The action copies bundled
extensions into `~/.local/share/gnome-shell/extensions/`, compiles schemas when
present, installs and verifies missing remote extensions, and treats the
resolved setup selection as the exact enabled-extension set. Installed
extensions that are not selected remain installed but are disabled, including
system extensions. An empty selection on a GNOME-derived setup disables all
optional extensions. Apply fails when a selected UUID cannot be installed or
enabled. This keeps extension source out of setup dotfile folders while keeping
extension selection in setup metadata.

`just save <setup>` performs the reverse workflow for deliberate imperative
edits. It reads each resolved dotfile from its installed home path and writes
changed content back to the owning `s.*` file while preserving removable target
markers. For GNOME-derived setups, it also records the currently enabled
extensions in the selected setup's `[gnome]` section; repository-bundled UUIDs
go to `extensions`, while all other enabled UUIDs go to `remote_extensions`.
The command only creates working-tree edits for review and does not commit.
`just save-dry <setup>` previews the same capture without writing files.

## Inheritance Model

When applying a setup, the resolver builds a lineage from `default` to the
requested setup.

Example:

```text
default -> gnome -> silverblue
default -> gnome -> bluefin
default -> hyprland
default -> mate-i3
```

Merge rules:

- Parent setups are read first.
- Child setups override parent files with the same basename.
- Distinct numbered scripts from each setup are kept.
- Dotfiles are keyed by basename and install target.
- It is an error for two different `s.*` files to resolve to the same target
  path unless the later setup is explicitly overriding the same basename.
- Setup `.Justfile` recipes supplement root recipes; root recipes remain the
  canonical interface.

Script execution order:

1. Build the merged file view for the selected setup.
2. Run scripts numbered `00` through `49`.
3. Apply all merged `s.*` settings.
4. Run scripts numbered `50` through `99`.

For scripts with the same numeric prefix, sort by full basename. If a child and
parent provide the same script basename, the child version wins.

## Settings Files

Settings files keep the old `s.<name>` convention.

The first line determines the target path:

```text
# .bashrc
```

or:

```text
.gitconfig
```

The apply engine should strip a leading comment marker and whitespace when
needed. The target path is always relative to `$HOME`.

Application behavior:

1. Resolve the target path from the first line.
2. Render the source into `.state/locks/<setup>/<basename>`.
3. Remove the target-path marker from the rendered copy when the marker is a
   comment.
4. Create the parent directory under `$HOME`.
5. Symlink `$HOME/<target>` to the rendered lock file.

This preserves the old behavior where the target path is documented inside the
setting file but does not leak into the installed file.

## Lifecycle Scripts

Lifecycle scripts use the `[0-9][0-9]-<name>.sh` convention, matching the
common Linux pattern used for ordered configuration snippets.

Script contract:

```bash
#!/usr/bin/env bash
# command -v gsettings >/dev/null
```

- The first line is the interpreter.
- The second line is a shell condition.
- The script runs only when the condition succeeds.
- Scripts do not need to be executable; the apply engine invokes the
  interpreter directly.

Numeric ranges:

- `00` to `19`: early environment checks and desktop prerequisites.
- `20` to `49`: pre-dotfile desktop or system state.
- `50` to `69`: editor, shell, and developer-tool finalization.
- `70` to `79`: user interface and workflow configuration.
- `80` to `89`: software shims, blobs, fonts, and permissions.
- `90` to `99`: cleanup, verification, and final messages.

Scripts should be idempotent whenever possible.

## Setup-Local `.Justfile`

Each setup may have a `.Justfile` for setup-specific install tasks.

Example:

```just
default:
    @just --list

install:
    ../../bin/settings install bluefin all

system:
    ../../bin/settings install bluefin bluefin-deps

desktop:
    ../../bin/settings apply bluefin
```

The root `Justfile` should remain the preferred entry point:

```bash
just apply bluefin
just install bluefin all
just software gh
```

Setup-local Justfiles are for convenience and for documenting setup-specific
intent near the setup data.

## Installation Design

Installation should be split into four layers:

1. Setup metadata selects groups.
2. Root install group files define package and provider-independent lists.
3. Provider helpers apply those groups with the correct system tool.
4. Named install actions and setup-local hooks handle imperative one-off work.

Example package groups:

```text
install/groups/
|-- fedora-deps.toml
|-- bluefin-deps.toml
|-- fedora-tools.toml
|-- desktop-hyprland.toml
|-- virt.toml
|-- rpm-build.toml
`-- openh264.toml
```

Example install actions:

```text
install/actions/
|-- enable-flathub.sh
|-- enable-hibernation.sh
|-- enable-rpmfusion.sh
|-- rpm-ostree-auto-updates.sh
|-- set-zsh-shell.sh
`-- gnome-nightly-flatpak.sh
```

Example provider helpers:

```text
install/providers/
|-- dnf.sh
|-- rpm-ostree.sh
|-- flatpak.sh
|-- brew.sh
`-- snap.sh
```

This keeps package lists reusable while still allowing setups to express a
complete machine profile.

Install groups use small TOML files:

```toml
description = "Core Fedora user packages used by the migrated dotfiles."
providers = ["dnf", "rpm-ostree"]
packages = ["kitty", "neovim", "zsh"]
remove = []
flatpaks = []
kargs = []
classic = []
```

`bin/settings-install <setup> <group> --dry-run --provider rpm-ostree` should
print provider commands without mutating the host. Omitting `<group>` applies
all inherited groups, actions, and hooks selected by the setup metadata.
Brew-only groups can use `providers = ["brew"]`; they are planned with the
Homebrew provider even when the rest of the setup uses `dnf` or `rpm-ostree`.
Snap-only groups can use `providers = ["snap"]`; `packages` map to
`snap install`, and `classic` maps to `snap install --classic`.

Provider helpers must be idempotent. Before calling a package manager, each
provider should filter the requested items down to the work that is still
needed: installed packages are skipped for `install`, absent packages are
skipped for `remove`, and rpm-ostree kernel args are checked before appending.
This keeps repeated `install` runs useful for drift repair without making every
run perform the same mutations again.

### Install Actions

Some install steps are neither package lists nor reusable provider behavior.
Examples include adding a COPR repository, enabling a systemd timer, changing a
default shell, writing a small config file, or applying a temporary workstation
quirk. These should be modeled as install actions.

Optional machine-specific actions, such as hibernation setup, should live here
but do not need to be selected by every setup. They can be run explicitly with
`bin/settings-install <setup> enable-hibernation --dry-run` and then without
`--dry-run` when the plan looks right.

Root-level actions live in `install/actions/<name>.sh` and are referenced by
name from setup metadata:

```toml
[install]
groups = ["bluefin-deps"]
actions = ["enable-flathub", "rpm-ostree-auto-updates", "set-zsh-shell"]
```

Setup-specific one-offs live in `setups/<setup>/install.d/`:

```text
setups/bluefin/install.d/
|-- 20-add-copr.sh
|-- 40-configure-rpm-ostreed.sh
`-- 80-postinstall-note.sh
```

Install action rules:

- Actions should be idempotent: check the target state first, print a short
  "already configured" message when satisfied, and exit successfully.
- Actions should have a narrow, named purpose.
- Actions should support a dry-run mode when practical.
- Actions should use shared helpers from `lib/install.sh` instead of
  duplicating provider logic.
- Setup-local hooks should use numeric prefixes for deterministic order.
- Inline shell commands should not be stored in `setup.toml`; a small named
  script is easier to lint, test, plan, and review.

Install execution order:

1. Resolve the setup inheritance chain.
2. Merge install groups and actions from parent to child.
3. Apply package groups through the selected provider helpers.
4. Run root-level named actions from `install/actions/`.
5. Run setup-local hooks from each inherited `install.d/` directory.

Root-level named actions are keyed by action name. If a child setup lists the
same action as a parent, it should run only once. Setup-local hooks are keyed by
basename; child hooks override parent hooks with the same basename.

## Migration From Reference Folder

The reference folder maps into the new design like this:

| Old reference item | New location |
| --- | --- |
| `apply` | `bin/settings-apply` plus `lib/apply.sh` |
| `s.*` | `setups/default/s.*` or a more specific setup |
| `[0-9][0-9].*.sh` | setup lifecycle scripts renamed to `[0-9][0-9]-*.sh` |
| `software-mono.sh` | `bin/settings-software` plus `lib/software.sh` |
| `software/*.sh` | `software/recipes/*.sh` |
| `install/*.sh` | `install/groups/`, `install/actions/`, `install/providers/`, setup `install.d/`, or setup `.Justfile` recipes |
| `misc/` | migrate case-by-case to setup files, root infra, or archived notes |

The first migration pass should place broadly useful dotfiles in
`setups/default/`. Desktop-specific files should move to setups such as
`setups/gnome/`, `setups/hyprland/`, `setups/mate-i3/`, or `setups/bluefin/`.

## Validation Expectations

`bin/settings-setup validate <setup>` should check:

- The requested setup exists.
- The inheritance chain reaches `default`.
- There are no inheritance cycles.
- Every setup has valid metadata.
- Every `s.*` file resolves to a target path.
- No two merged settings collide on target path unexpectedly.
- Lifecycle scripts are named `[0-9][0-9]-*.sh` and have a shebang and condition line.
- Setup install groups exist.
- Setup install actions exist under `install/actions/`.
- Setup-local install hooks are named `[0-9][0-9]-*.sh` and have a shebang.
- Software targets listed in setup metadata have recipes.

Validation should be safe to run on any machine and should not mutate the host.

## Testing Design

Testing should be part of the repository design from the beginning. The safest
testing model is to make the settings system produce a plan that can be
inspected without mutating the current machine.

`bin/settings-apply --plan <setup>` should emit stable JSON describing:

- The resolved setup lineage.
- The merged lifecycle scripts in execution order.
- The merged settings files and their target paths.
- Any setup-local Just recipes discovered.
- Install groups selected by setup metadata.
- Install actions and setup-local install hooks in execution order.
- Software targets and shim actions selected by setup metadata.

This plan output becomes the main unit-test surface. Tests can compare parsed
JSON against expected behavior without touching `$HOME`, installing packages, or
running host-specific commands.

Suggested test layout:

```text
tests/
|-- fixtures/
|   `-- setups/
|       |-- default/
|       |-- gnome/
|       `-- bluefin/
|-- unit/
|   |-- test_setup_resolver.py
|   |-- test_setting_parser.py
|   |-- test_apply_plan.py
|   |-- test_install_groups.py
|   `-- test_software_recipes.py
`-- integration/
    `-- test_apply_fake_home.py
```

Recommended unit tests:

- Setup inheritance resolves from `default` to the selected setup.
- Missing parents, missing setups, and inheritance cycles fail clearly.
- Child setup files override parent files with the same basename.
- Distinct numbered scripts from parent and child setups are preserved.
- Lifecycle scripts are ordered `00-49`, then settings, then `50-99`.
- Setting target paths are parsed from first-line markers such as `# .bashrc`,
  `.gitconfig`, `-- .config/nvim/init.lua`, and `/* .config/...`.
- Two different settings cannot target the same home path unless the conflict
  is an intentional override.
- Install groups referenced by setup metadata exist under `install/groups/`.
- Install actions referenced by setup metadata exist under `install/actions/`.
- Setup-local `install.d/` hooks are ordered deterministically and inherited
  correctly.
- Software targets referenced by setup metadata have recipes.
- Software recipe discovery maps every advertised binary to exactly one recipe.

Recommended integration tests:

- Apply a fixture setup into a temporary `$HOME`.
- Write lock files into a temporary state directory.
- Verify symlinks are created under the fake home.
- Verify rendered setting files do not include the target-path marker when it
  was only a comment.
- Verify lifecycle scripts can be planned without being executed.

Tests should use Python's standard `unittest` first to keep the bootstrap path
small. `pytest` can be introduced later if its fixtures and assertion output
become worth the dependency.

Root Just recipes should include:

```just
test:
    python -m unittest discover -s tests

validate setup="default":
    bin/settings-setup validate {{setup}}

validate-all:
    for setup in $(bin/settings-setup list); do bin/settings-setup validate "$setup"; done

ci:
    just validate-all
    just test

ci-podman:
    podman run --rm -it -v "$PWD:/workspace:Z" -w /workspace fedora:latest bash -lc 'dnf install -y python3 bash just ShellCheck && just ci'
```

`just ci` should be the command that local development and GitHub Actions both
run. `just ci-podman` should be the fast local Fedora-container path. It does
not emulate the entire GitHub Actions workflow, but it should run the same core
validation command in a clean Fedora environment.

## GitHub Actions Design

GitHub Actions should be used to continuously check the repository without
mutating the runner as though it were a real workstation.

Suggested workflow file:

```text
.github/
`-- workflows/
    `-- ci.yml
```

The CI workflow should run on:

- Pull requests.
- Pushes to the main branch.
- Manual `workflow_dispatch` runs.
- A weekly schedule for drift checks.

Recommended jobs:

- `unit`: run Python unit tests and basic shell syntax checks.
- `fedora`: run validation inside a Fedora container to stay close to the
  target operating system.
- `lint`: run `shellcheck`, `shfmt --diff`, and future formatting checks when
  those tools are available.
- `dry-run`: run `bin/settings-apply --plan` and setup validation for each
  supported setup.

Example workflow:

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:
  schedule:
    - cron: "0 10 * * 0"

permissions:
  contents: read

jobs:
  unit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: "3.13"
      - run: python -m unittest discover -s tests
      - run: bash -n bin/settings-apply bin/settings-setup bin/settings-software

  fedora:
    runs-on: ubuntu-latest
    container:
      image: fedora:latest
    defaults:
      run:
        shell: bash
    steps:
      - uses: actions/checkout@v6
      - run: dnf install -y python3 bash just ShellCheck
      - run: just ci
      - run: shellcheck bin/* lib/*.sh software/recipes/*.sh
```

GitHub Actions safety rules:

- CI must use dry-run, plan, validation, or fake-home modes for host mutation.
- CI must not run real `rpm-ostree`, `dnf install` for workstation packages,
  Flatpak installs, shell changes, home-directory mutation, or reboot commands.
- CI may install test-only tools inside an Actions runner or container.
- CI should upload plan output or logs as workflow artifacts when failures need
  easier debugging.
- Dependency caching should be added only if Python or tooling dependencies
  become slow enough to justify it.

The scheduled workflow can perform lightweight drift checks, such as confirming
that software recipe metadata is parseable and that known GitHub release URLs
still have a latest release. Network-heavy checks should stay separate from the
required pull-request path.

## Design Decisions To Keep Stable

- `default` is the root setup name.
- Setups describe desired state; root infra performs actions.
- Dotfile names keep the `s.*` convention.
- Lifecycle script names keep the two-digit prefix convention.
- Settings are applied between script ranges `00-49` and `50-99`.
- Just is the public command interface, but direct scripts remain usable for
  bootstrap and recovery.
- Generated lock files and install state are not tracked source.
