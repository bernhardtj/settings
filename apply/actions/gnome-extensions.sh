#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
bundle_root="${SETTINGS_GNOME_EXTENSIONS_DIR:-$repo_root/gnome-extensions}"
target_root="${SETTINGS_GNOME_EXTENSIONS_TARGET:-$HOME/.local/share/gnome-shell/extensions}"

log() {
    printf 'gnome-extensions: %s\n' "$*"
}

fail() {
    printf 'gnome-extensions: %s\n' "$*" >&2
    return 1
}

read_lines() {
    local value="$1"
    [[ -n $value ]] || return 0
    while IFS= read -r line; do
        [[ -n $line ]] || continue
        printf '%s\n' "$line"
    done <<<"$value"
}

append_unique() {
    local array_name="$1"
    local value="$2"
    local -n values="$array_name"
    local existing

    for existing in "${values[@]}"; do
        [[ $existing == "$value" ]] && return 0
    done
    values+=("$value")
}

array_contains() {
    local needle="$1"
    shift
    local value

    for value in "$@"; do
        [[ $value == "$needle" ]] && return 0
    done
    return 1
}

desktop_is_gnome() {
    [[ ${SETTINGS_GNOME_EXTENSIONS_FORCE:-} == 1 ]] ||
        [[ ${SETTINGS_GNOME_EXTENSIONS_FORCE:-} == true ]] ||
        [[ ${XDG_CURRENT_DESKTOP:-} == *GNOME* ]]
}

enforcement_enabled() {
    [[ ${SETTINGS_GNOME_EXTENSIONS_ENABLE:-1} != 0 &&
        ${SETTINGS_GNOME_EXTENSIONS_ENABLE:-1} != false ]]
}

gsettings_enabled() {
    [[ ${SETTINGS_GNOME_EXTENSIONS_GSETTINGS:-1} != 0 &&
        ${SETTINGS_GNOME_EXTENSIONS_GSETTINGS:-1} != false ]] &&
        command -v gsettings >/dev/null 2>&1
}

require_extension_command() {
    command -v gnome-extensions >/dev/null 2>&1 ||
        fail "gnome-extensions command is required to enforce extension state"
}

list_installed_extensions() {
    gnome-extensions list 2>/dev/null
}

list_enabled_extensions() {
    gnome-extensions list --enabled 2>/dev/null
}

extension_installed() {
    local uuid="$1"
    list_installed_extensions | grep -Fxq "$uuid"
}

extension_enabled() {
    local uuid="$1"
    list_enabled_extensions | grep -Fxq "$uuid"
}

encode_gsettings_array() {
    command -v python3 >/dev/null 2>&1 ||
        fail "python3 is required to encode GNOME extension settings"

    python3 - "$@" <<'PY'
import sys

print("[" + ", ".join(repr(value) for value in sys.argv[1:]) + "]")
PY
}

write_exact_gsettings() {
    local selected_name="$1"
    local disabled_name="$2"
    local -n selected_values="$selected_name"
    local -n disabled_values="$disabled_name"

    if ! gsettings_enabled; then
        log "GSettings reconciliation disabled by environment"
        return 0
    fi

    local enabled_value
    local disabled_value
    enabled_value="$(encode_gsettings_array "${selected_values[@]}")"
    disabled_value="$(encode_gsettings_array "${disabled_values[@]}")"

    gsettings set org.gnome.shell disabled-extensions "$disabled_value"
    gsettings set org.gnome.shell enabled-extensions "$enabled_value"
    gsettings set org.gnome.shell disable-user-extensions false
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
    [[ ${SETTINGS_GNOME_EXTENSIONS_CREATE:-1} != 0 &&
        ${SETTINGS_GNOME_EXTENSIONS_CREATE:-1} != false ]] || return 0
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

    [[ -d $source ]] || fail "bundled extension does not exist: $uuid"
    [[ -f "$source/metadata.json" ]] || fail "bundled extension missing metadata.json: $uuid"

    mkdir -p "$target_root"
    bootstrap_extension_template "$uuid" "$source" "$target"
    mkdir -p "$target"
    find "$target" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -a "$source"/. "$target"/

    if [[ -d "$target/schemas" ]] && command -v glib-compile-schemas >/dev/null 2>&1; then
        glib-compile-schemas "$target/schemas"
    fi

    log "installed bundled extension: $uuid"
}

verify_bundled_extension() {
    local uuid="$1"

    if extension_installed "$uuid"; then
        return 0
    fi

    if command -v busctl >/dev/null 2>&1; then
        busctl --user call org.gnome.Shell.Extensions /org/gnome/Shell/Extensions \
            org.gnome.Shell.Extensions ReloadExtension s "$uuid" >/dev/null 2>&1 || true
    fi

    local attempts="${SETTINGS_GNOME_LOCAL_INSTALL_ATTEMPTS:-40}"
    local attempt
    for ((attempt = 0; attempt < attempts; attempt++)); do
        extension_installed "$uuid" && return 0
        sleep 0.25
    done

    fail "bundled extension was copied but GNOME did not register it: $uuid"
}

install_remote_extension() {
    local uuid="$1"

    if extension_installed "$uuid"; then
        log "remote extension already installed: $uuid"
        return 0
    fi

    command -v busctl >/dev/null 2>&1 ||
        fail "busctl is required to install remote extension: $uuid"

    local response
    if ! response="$(busctl --user call \
        org.gnome.Shell.Extensions \
        /org/gnome/Shell/Extensions \
        org.gnome.Shell.Extensions \
        InstallRemoteExtension s "$uuid" 2>&1)"; then
        fail "failed to request remote extension install: $uuid: $response"
    fi

    local attempts="${SETTINGS_GNOME_REMOTE_INSTALL_ATTEMPTS:-40}"
    local attempt
    for ((attempt = 0; attempt < attempts; attempt++)); do
        if extension_installed "$uuid"; then
            log "installed remote extension: $uuid"
            return 0
        fi
        sleep 0.25
    done

    fail "remote extension was not installed: $uuid (service response: $response)"
}

reconcile_extensions() {
    local desired_name="$1"
    local -n desired="$desired_name"
    local installed=()
    local disabled=()
    local enabled=()
    local uuid

    mapfile -t installed < <(list_installed_extensions)

    for uuid in "${desired[@]}"; do
        array_contains "$uuid" "${installed[@]}" ||
            fail "selected extension is not installed: $uuid"
    done

    for uuid in "${installed[@]}"; do
        if ! array_contains "$uuid" "${desired[@]}"; then
            disabled+=("$uuid")
        fi
    done

    write_exact_gsettings "$desired_name" disabled

    for uuid in "${desired[@]}"; do
        if extension_enabled "$uuid"; then
            log "already enabled: $uuid"
        elif gnome-extensions enable "$uuid" >/dev/null 2>&1; then
            log "enabled: $uuid"
        else
            fail "failed to enable selected extension: $uuid"
        fi
    done

    for uuid in "${disabled[@]}"; do
        if extension_enabled "$uuid"; then
            if gnome-extensions disable "$uuid" >/dev/null 2>&1; then
                log "disabled unselected extension: $uuid"
            else
                fail "failed to disable unselected extension: $uuid"
            fi
        fi
    done

    write_exact_gsettings "$desired_name" disabled

    mapfile -t enabled < <(list_enabled_extensions)
    for uuid in "${desired[@]}"; do
        array_contains "$uuid" "${enabled[@]}" ||
            fail "selected extension is not enabled after reconciliation: $uuid"
    done
    for uuid in "${enabled[@]}"; do
        array_contains "$uuid" "${desired[@]}" ||
            fail "unselected extension remains enabled after reconciliation: $uuid"
    done
}

if ! desktop_is_gnome; then
    log "not running under GNOME; skipping"
    exit 0
fi

mapfile -t bundled_extensions < <(read_lines "${SETTINGS_GNOME_EXTENSIONS:-}")
mapfile -t remote_extensions < <(read_lines "${SETTINGS_GNOME_REMOTE_EXTENSIONS:-}")
desired_extensions=()

for uuid in "${bundled_extensions[@]}"; do
    append_unique desired_extensions "$uuid"
done
for uuid in "${remote_extensions[@]}"; do
    append_unique desired_extensions "$uuid"
done

for uuid in "${bundled_extensions[@]}"; do
    install_bundled_extension "$uuid"
done

if enforcement_enabled; then
    require_extension_command
    for uuid in "${bundled_extensions[@]}"; do
        verify_bundled_extension "$uuid"
    done
    for uuid in "${remote_extensions[@]}"; do
        install_remote_extension "$uuid"
    done
    reconcile_extensions desired_extensions
else
    log "extension state enforcement disabled by environment"
fi
