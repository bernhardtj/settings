#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bundle_root="${SETTINGS_GNOME_EXTENSIONS_DIR:-$repo_root/gnome-extensions}"
target_root="${SETTINGS_GNOME_EXTENSIONS_TARGET:-$HOME/.local/share/gnome-shell/extensions}"

log() {
    printf 'gnome-extensions: %s\n' "$*"
}

read_lines() {
    local value="$1"
    [[ -n $value ]] || return 0
    while IFS= read -r line; do
        [[ -n $line ]] || continue
        printf '%s\n' "$line"
    done <<<"$value"
}

desktop_is_gnome() {
    [[ ${SETTINGS_GNOME_EXTENSIONS_FORCE:-} == 1 ]] ||
        [[ ${SETTINGS_GNOME_EXTENSIONS_FORCE:-} == true ]] ||
        [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]]
}

gsettings_enabled() {
    [[ ${SETTINGS_GNOME_EXTENSIONS_GSETTINGS:-1} != 0 &&
        ${SETTINGS_GNOME_EXTENSIONS_GSETTINGS:-1} != false &&
        $(command -v gsettings || true) ]]
}

extension_enabled_in_gsettings() {
    local uuid="$1"
    gsettings_enabled || return 1
    gsettings get org.gnome.shell enabled-extensions 2>/dev/null | grep -Fq "'$uuid'"
}

update_gsettings_extension_lists() {
    local uuid="$1"
    gsettings_enabled || return 0
    command -v python3 >/dev/null 2>&1 || return 0

    python3 - "$uuid" <<'PY'
import ast
import subprocess
import sys

UUID = sys.argv[1]
SCHEMA = "org.gnome.shell"


def read_list(key):
    try:
        raw = subprocess.check_output(
            ["gsettings", "get", SCHEMA, key],
            stderr=subprocess.DEVNULL,
            text=True,
        ).strip()
        parsed = ast.literal_eval(raw)
    except Exception:
        return None
    if not isinstance(parsed, list):
        return None
    return [str(value) for value in parsed]


def write_list(key, values):
    encoded = "[" + ", ".join(repr(value) for value in values) + "]"
    subprocess.check_call(
        ["gsettings", "set", SCHEMA, key, encoded],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


enabled = read_list("enabled-extensions")
if enabled is not None and UUID not in enabled:
    enabled.append(UUID)
    write_list("enabled-extensions", enabled)

disabled = read_list("disabled-extensions")
if disabled is not None and UUID in disabled:
    write_list("disabled-extensions", [value for value in disabled if value != UUID])
PY
}

enable_extension() {
    local uuid="$1"
    if [[ ${SETTINGS_GNOME_EXTENSIONS_ENABLE:-1} == 0 || ${SETTINGS_GNOME_EXTENSIONS_ENABLE:-1} == false ]]; then
        log "enable disabled by environment: $uuid"
        return
    fi
    if update_gsettings_extension_lists "$uuid"; then
        :
    else
        log "could not update GNOME Shell extension settings: $uuid"
    fi
    if ! command -v gnome-extensions >/dev/null 2>&1; then
        log "gnome-extensions command not available; selected $uuid for the next GNOME Shell refresh"
        return
    fi
    if gnome-extensions list --enabled 2>/dev/null | grep -Fxq "$uuid"; then
        log "already enabled: $uuid"
        return
    fi
    if ! gnome-extensions list 2>/dev/null | grep -Fxq "$uuid"; then
        log "selected for the next GNOME Shell refresh: $uuid"
        return
    fi
    if ! gnome-extensions enable "$uuid" >/dev/null 2>&1; then
        log "enable command could not see $uuid; selected it for the next GNOME Shell refresh"
    fi
}

metadata_value() {
    local metadata="$1"
    local key="$2"
    local fallback="$3"

    if ! command -v python3 >/dev/null 2>&1; then
        printf '%s\n' "$fallback"
        return
    fi

    python3 - "$metadata" "$key" "$fallback" <<'PY'
import json
import sys

metadata, key, fallback = sys.argv[1:]
try:
    value = json.loads(open(metadata, encoding="utf-8").read()).get(key) or fallback
except Exception:
    value = fallback
print(value)
PY
}

bootstrap_extension_template() {
    local uuid="$1"
    local source="$2"
    local target="$3"
    local default_target="$HOME/.local/share/gnome-shell/extensions"

    [[ ! -d $target ]] || return 0
    [[ $target_root == "$default_target" ]] || return 0
    [[ ${SETTINGS_GNOME_EXTENSIONS_CREATE:-1} != 0 && ${SETTINGS_GNOME_EXTENSIONS_CREATE:-1} != false ]] || return 0
    command -v gnome-extensions >/dev/null 2>&1 || return 0

    local metadata="$source/metadata.json"
    local name
    local description
    name="$(metadata_value "$metadata" name "$uuid")"
    description="$(metadata_value "$metadata" description "Bundled settings extension $uuid")"

    if gnome-extensions create \
        --uuid="$uuid" \
        --name="$name" \
        --description="$description" \
        --template=plain \
        --quiet; then
        log "created GNOME extension template: $uuid"
    else
        log "could not create GNOME extension template; copying bundle directly: $uuid"
    fi
}

install_bundled_extension() {
    local uuid="$1"
    local source="$bundle_root/$uuid"
    local target="$target_root/$uuid"

    if [[ ! -d $source ]]; then
        echo "gnome-extensions: bundled extension does not exist: $uuid" >&2
        return 1
    fi
    if [[ ! -f "$source/metadata.json" ]]; then
        echo "gnome-extensions: bundled extension missing metadata.json: $uuid" >&2
        return 1
    fi

    mkdir -p "$target_root"
    bootstrap_extension_template "$uuid" "$source" "$target"
    mkdir -p "$target"
    find "$target" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -a "$source"/. "$target"/

    if [[ -d "$target/schemas" ]] && command -v glib-compile-schemas >/dev/null 2>&1; then
        glib-compile-schemas "$target/schemas"
    fi

    log "installed bundled extension: $uuid"
    enable_extension "$uuid"
}

install_remote_extension() {
    local uuid="$1"

    if extension_enabled_in_gsettings "$uuid"; then
        log "remote extension already selected: $uuid"
        enable_extension "$uuid"
        return
    fi

    if ! command -v gnome-extensions >/dev/null 2>&1; then
        log "gnome-extensions command not available; skipping remote extension $uuid"
        enable_extension "$uuid"
        return
    fi

    if ! gnome-extensions list 2>/dev/null | grep -Fxq "$uuid"; then
        if ! busctl --user call \
            org.gnome.Shell.Extensions \
            /org/gnome/Shell/Extensions \
            org.gnome.Shell.Extensions \
            InstallRemoteExtension s "$uuid" >/dev/null 2>&1; then
            log "could not install remote extension now; selected it for the next GNOME Shell refresh: $uuid"
        fi
    else
        log "remote extension already installed: $uuid"
    fi

    enable_extension "$uuid"
}

if ! desktop_is_gnome; then
    log "not running under GNOME; skipping"
    exit 0
fi

if gsettings_enabled; then
    gsettings reset org.gnome.shell disable-user-extensions || true
fi

while IFS= read -r uuid; do
    install_bundled_extension "$uuid"
done < <(read_lines "${SETTINGS_GNOME_EXTENSIONS:-}")

while IFS= read -r uuid; do
    install_remote_extension "$uuid"
done < <(read_lines "${SETTINGS_GNOME_REMOTE_EXTENSIONS:-}")
