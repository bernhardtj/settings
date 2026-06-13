#!/usr/bin/env bash
set -euo pipefail

operation="${1:-}"
[[ $# -gt 0 ]] && shift || true

if ! command -v flatpak >/dev/null 2>&1; then
    echo "flatpak provider: flatpak is not available" >&2
    exit 1
fi

ref_installed() {
    flatpak info "$1" >/dev/null 2>&1
}

missing_refs() {
    local ref
    for ref in "$@"; do
        if ref_installed "$ref"; then
            echo "flatpak provider: already installed: $ref" >&2
        else
            printf '%s\n' "$ref"
        fi
    done
}

case "$operation" in
install)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t refs < <(missing_refs "$@")
    [[ ${#refs[@]} -gt 0 ]] || {
        echo "flatpak provider: nothing to install" >&2
        exit 0
    }
    flatpak install -y flathub "${refs[@]}"
    ;;
*)
    echo "flatpak provider: unknown operation: $operation" >&2
    exit 1
    ;;
esac
