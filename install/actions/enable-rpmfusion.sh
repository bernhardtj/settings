#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/lib/install.sh"

fedora_version="$(rpm -E %fedora)"
free_repo="/etc/yum.repos.d/rpmfusion-free.repo"
nonfree_repo="/etc/yum.repos.d/rpmfusion-nonfree.repo"

log() {
    printf 'enable-rpmfusion: %s\n' "$*"
}

get_rpm_url() {
    local channel="$1"
    echo "https://mirrors.rpmfusion.org/$channel/fedora/rpmfusion-$channel-release-${fedora_version}.noarch.rpm"
}

rpmfusion_repo_files_exist() {
    [[ -f $free_repo && -f $nonfree_repo ]]
}

rpmfusion_release_packages_installed() {
    rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1
}

rpm_ostree_release_packages_requested() {
    command -v rpm-ostree >/dev/null 2>&1 || return 1
    command -v python3 >/dev/null 2>&1 || return 1

    rpm-ostree status --json 2>/dev/null | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)

required = {"rpmfusion-free-release", "rpmfusion-nonfree-release"}
for deployment in data.get("deployments", []):
    values = set()
    for key in ("packages", "requested-packages", "requested-local-packages", "inactive-requests"):
        for value in deployment.get(key) or []:
            text = str(value)
            values.add(text)
            for package in required:
                if text == package or text.startswith(package + "-"):
                    values.add(package)
    if required <= values:
        sys.exit(0)
sys.exit(1)
'
}

rpmfusion_ready() {
    rpmfusion_repo_files_exist &&
        { rpmfusion_release_packages_installed || rpm_ostree_release_packages_requested; }
}

install_release_rpms_into_root() {
    if rpmfusion_repo_files_exist; then
        log "repo files already exist"
        return
    fi

    if settings_dry_run; then
        echo "+ curl -sL $(get_rpm_url free) | sudo sh -c 'cd / && rpm2cpio | cpio -idmu'"
        echo "+ curl -sL $(get_rpm_url nonfree) | sudo sh -c 'cd / && rpm2cpio | cpio -idmu'"
        return
    fi

    for channel in free nonfree; do
        curl -sL "$(get_rpm_url "$channel")" | sudo sh -c 'cd / && rpm2cpio | cpio -idmu'
    done
}

refresh_rpm_ostree_layering() {
    if ! command -v rpm-ostree >/dev/null 2>&1; then
        return
    fi

    if rpmfusion_ready; then
        log "rpm-ostree release packages already installed or requested"
        return
    fi

    settings_run rpm-ostree update \
        --uninstall rpmfusion-free-release \
        --uninstall rpmfusion-nonfree-release \
        --install rpmfusion-free-release \
        --install rpmfusion-nonfree-release
}

install_dnf_release_packages() {
    if ! command -v dnf5 >/dev/null 2>&1 && ! command -v dnf >/dev/null 2>&1; then
        return
    fi

    if rpmfusion_ready; then
        log "dnf release packages already installed"
        return
    fi

    local dnf_bin
    dnf_bin="$(command -v dnf5 || command -v dnf)"
    settings_run sudo "$dnf_bin" install -y "$(get_rpm_url free)" "$(get_rpm_url nonfree)"
}

if rpmfusion_ready; then
    log "rpmfusion already appears enabled"
    exit 0
fi

install_release_rpms_into_root

if [[ -e /run/ostree-booted ]]; then
    refresh_rpm_ostree_layering
else
    install_dnf_release_packages
fi
