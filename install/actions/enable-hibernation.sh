#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/lib/install.sh"

swapfile="${SETTINGS_HIBERNATION_SWAPFILE:-/var/swap/swapfile}"
swapdir="$(dirname "$swapfile")"
swap_margin_gib="${SETTINGS_HIBERNATION_SWAP_MARGIN_GIB:-1}"
swap_size="${SETTINGS_HIBERNATION_SWAP_SIZE:-}"
hibernate_delay="${SETTINGS_HIBERNATION_DELAY:-2h}"
logind_dropin="/etc/systemd/logind.conf.d/99-settings-hibernation.conf"
sleep_dropin="/etc/systemd/sleep.conf.d/99-settings-hibernation.conf"
root_files_changed=0

log() {
    printf 'enable-hibernation: %s\n' "$*"
}

mem_total_kib() {
    awk '/^MemTotal:/ { print $2 }' /proc/meminfo
}

required_swap_size() {
    if [[ -n $swap_size ]]; then
        echo "$swap_size"
        return
    fi

    local mem_kib ram_gib total_gib
    mem_kib="$(mem_total_kib)"
    ram_gib=$(((mem_kib + 1048576 - 1) / 1048576))
    total_gib=$((ram_gib + swap_margin_gib))
    echo "${total_gib}G"
}

swapfile_large_enough() {
    [[ -f $swapfile ]] || return 1

    local size_bytes size_kib
    size_bytes="$(stat -c '%s' "$swapfile")"
    size_kib=$((size_bytes / 1024))
    [[ $size_kib -ge "$(mem_total_kib)" ]]
}

swapfile_active() {
    awk -v swapfile="$swapfile" '$1 == swapfile { found = 1 } END { exit !found }' /proc/swaps
}

fstab_has_swapfile() {
    awk -v swapfile="$swapfile" '$1 == swapfile && $3 == "swap" { found = 1 } END { exit !found }' /etc/fstab
}

is_laptop() {
    case "${SETTINGS_HIBERNATION_LAPTOP:-auto}" in
    1 | true | yes)
        return 0
        ;;
    0 | false | no)
        return 1
        ;;
    esac

    local path chassis_type
    for path in /sys/class/dmi/id/chassis_type /sys/devices/virtual/dmi/id/chassis_type; do
        [[ -r $path ]] || continue
        chassis_type="$(cat "$path")"
        case "$chassis_type" in
        8 | 9 | 10 | 14 | 30 | 31 | 32)
            return 0
            ;;
        esac
    done
    return 1
}

file_contains() {
    local path="$1"
    local pattern="$2"
    [[ -r $path ]] && grep -qF "$pattern" "$path"
}

laptop_dropins_configured() {
    if ! is_laptop; then
        return 0
    fi

    file_contains "$logind_dropin" "HandleLidSwitch=suspend-then-hibernate" &&
        file_contains "$sleep_dropin" "HibernateDelaySec=$hibernate_delay"
}

hibernation_already_enabled() {
    swapfile_large_enough &&
        fstab_has_swapfile &&
        swapfile_active &&
        laptop_dropins_configured
}

parent_fstype() {
    findmnt -no FSTYPE --target "$(dirname "$swapdir")" 2>/dev/null ||
        stat -f -c '%T' "$(dirname "$swapdir")"
}

ensure_swap_directory() {
    if [[ -d $swapdir ]]; then
        log "swap directory already exists: $swapdir"
        return
    fi

    if [[ "$(parent_fstype)" == btrfs ]]; then
        settings_run sudo btrfs subvolume create "$swapdir"
    else
        settings_run sudo install -d -m 0755 "$swapdir"
    fi
}

ensure_swapfile() {
    local size
    size="$(required_swap_size)"

    if [[ -f $swapfile ]]; then
        if swapfile_large_enough; then
            log "swapfile already exists and is at least RAM-sized: $swapfile"
            return
        fi
        log "existing swapfile is smaller than RAM: $swapfile"
        log "refusing to replace an existing swapfile unattended"
        return 1
    fi

    if [[ "$(parent_fstype)" == btrfs ]]; then
        settings_run sudo btrfs filesystem mkswapfile --size "$size" --uuid clear "$swapfile"
    else
        settings_run sudo fallocate -l "$size" "$swapfile"
        settings_run sudo chmod 600 "$swapfile"
        settings_run sudo mkswap -U clear "$swapfile"
    fi
}

ensure_fstab() {
    if fstab_has_swapfile; then
        log "fstab already contains swapfile entry"
        return
    fi

    local line
    line="$swapfile none swap defaults 0 0"
    if settings_dry_run; then
        printf '+ printf %%s\\\\n %q | sudo tee -a /etc/fstab >/dev/null\n' "$line"
    else
        printf '%s\n' "$line" | sudo tee -a /etc/fstab >/dev/null
    fi
}

ensure_selinux_context() {
    command -v getenforce >/dev/null 2>&1 || return 0
    [[ "$(getenforce)" != Disabled ]] || return 0

    if command -v semanage >/dev/null 2>&1; then
        if settings_dry_run; then
            echo "+ sudo semanage fcontext --add --type swapfile_t $swapfile || sudo semanage fcontext --modify --type swapfile_t $swapfile"
        else
            sudo semanage fcontext --add --type swapfile_t "$swapfile" 2>/dev/null ||
                sudo semanage fcontext --modify --type swapfile_t "$swapfile"
        fi
        settings_run sudo restorecon -RF "$swapdir"
    elif command -v chcon >/dev/null 2>&1; then
        settings_run sudo chcon --type swapfile_t "$swapfile"
    else
        log "SELinux is enabled, but neither semanage nor chcon is available"
    fi
}

ensure_swap_active() {
    if swapfile_active; then
        log "swapfile is already active"
        return
    fi

    settings_run sudo swapon --verbose "$swapfile"
}

write_root_file() {
    local path="$1"
    local mode="${2:-0644}"
    local content
    content="$(cat)"

    if settings_dry_run; then
        printf '+ sudo install -Dm%s <content> %q\n' "$mode" "$path"
        root_files_changed=1
        return
    fi

    local tmp
    tmp="$(mktemp)"
    printf '%s\n' "$content" >"$tmp"
    if [[ -f $path ]] && sudo cmp -s "$tmp" "$path"; then
        rm -f "$tmp"
        log "already configured: $path"
        return
    fi
    sudo install -Dm"$mode" "$tmp" "$path"
    root_files_changed=1
    rm -f "$tmp"
}

ensure_laptop_systemd_dropins() {
    if ! is_laptop; then
        log "machine does not look like a laptop; skipping lid/sleep drop-ins"
        return
    fi

    write_root_file "$logind_dropin" 0644 <<EOF
[Login]
HandleLidSwitch=suspend-then-hibernate
HandleLidSwitchExternalPower=suspend-then-hibernate
HandleLidSwitchDocked=ignore
EOF

    write_root_file "$sleep_dropin" 0644 <<EOF
[Sleep]
AllowSuspend=yes
AllowHibernation=yes
AllowSuspendThenHibernate=yes
HibernateDelaySec=$hibernate_delay
EOF

    if [[ $root_files_changed == 1 ]]; then
        settings_run sudo systemctl daemon-reload
        if [[ ${SETTINGS_HIBERNATION_RELOAD_LOGIND:-1} == 1 ]]; then
            settings_run sudo systemctl try-reload-or-restart systemd-logind.service
        fi
    else
        log "laptop systemd drop-ins already configured"
    fi
}

if hibernation_already_enabled; then
    log "hibernation appears to be enabled already; nothing to do"
    exit 0
fi

ensure_swap_directory
ensure_swapfile
ensure_fstab
ensure_selinux_context
ensure_swap_active
ensure_laptop_systemd_dropins

log "configured hibernation swapfile at $swapfile"
