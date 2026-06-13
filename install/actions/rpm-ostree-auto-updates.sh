#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/lib/install.sh"

target_conf="/etc/rpm-ostreed.conf"
source_conf="/usr/etc/rpm-ostreed.conf"
timer="rpm-ostreed-automatic.timer"

log() {
    printf 'rpm-ostree-auto-updates: %s\n' "$*"
}

auto_updates_configured() {
    [[ -f $target_conf ]] && grep -Eq '^AutomaticUpdatePolicy=stage$' "$target_conf"
}

write_auto_update_config() {
    if auto_updates_configured; then
        log "AutomaticUpdatePolicy already set to stage"
        return
    fi

    if settings_dry_run; then
        echo "+ sudo install -Dm0644 <rpm-ostreed stage config> $target_conf"
        return
    fi

    if [[ ! -r $source_conf ]]; then
        echo "rpm-ostree-auto-updates: missing source config: $source_conf" >&2
        exit 1
    fi

    tmp="$(mktemp)"
    sed \
        -e 's/^#AutomaticUpdatePolicy=/AutomaticUpdatePolicy=/' \
        -e 's/^AutomaticUpdatePolicy=.*/AutomaticUpdatePolicy=stage/' \
        "$source_conf" >"$tmp"
    sudo install -Dm0644 "$tmp" "$target_conf"
    rm -f "$tmp"
}

timer_enabled_and_active() {
    systemctl is-enabled --quiet "$timer" &&
        systemctl is-active --quiet "$timer"
}

write_auto_update_config

if timer_enabled_and_active; then
    log "$timer already enabled and active"
else
    settings_run sudo systemctl enable --now "$timer"
fi
