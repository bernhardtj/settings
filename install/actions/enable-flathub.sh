#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/lib/install.sh"

log() {
    printf 'enable-flathub: %s\n' "$*"
}

if settings_dry_run; then
    settings_run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    settings_run flatpak remote-modify --enable flathub
    exit 0
fi

if ! command -v flatpak >/dev/null 2>&1; then
    echo "enable-flathub: flatpak is not available" >&2
    exit 1
fi

remote_exists() {
    flatpak remotes --show-disabled --columns=name | grep -Fxq flathub
}

remote_disabled() {
    flatpak remotes --show-disabled --columns=name,options |
        awk '$1 == "flathub" && $0 ~ /disabled/ { found = 1 } END { exit !found }'
}

if remote_exists; then
    log "remote already exists"
else
    settings_run flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if remote_disabled; then
    settings_run flatpak remote-modify --enable flathub
else
    log "remote already enabled"
fi
