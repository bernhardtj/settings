#!/usr/bin/env bash
set -euo pipefail

operation="${1:-}"
[[ $# -gt 0 ]] && shift || true

dnf_bin="$(command -v dnf5 || command -v dnf || true)"
if [[ -z $dnf_bin ]]; then
    echo "dnf provider: neither dnf5 nor dnf is available" >&2
    exit 1
fi

run_as_root() {
    if [[ $UID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

is_rpm_reference() {
    [[ $1 == http://* || $1 == https://* || $1 == *.rpm || $1 == /*.rpm ]]
}

package_installed() {
    local package="$1"
    is_rpm_reference "$package" && return 1
    rpm -q "$package" >/dev/null 2>&1
}

missing_packages() {
    local package
    for package in "$@"; do
        if package_installed "$package"; then
            echo "dnf provider: already installed: $package" >&2
        else
            printf '%s\n' "$package"
        fi
    done
}

installed_packages() {
    local package
    for package in "$@"; do
        if package_installed "$package"; then
            printf '%s\n' "$package"
        else
            echo "dnf provider: already absent: $package" >&2
        fi
    done
}

case "$operation" in
install)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(missing_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "dnf provider: nothing to install" >&2
        exit 0
    }
    run_as_root "$dnf_bin" install -y "${packages[@]}"
    ;;
remove)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(installed_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "dnf provider: nothing to remove" >&2
        exit 0
    }
    run_as_root "$dnf_bin" remove -y "${packages[@]}"
    ;;
*)
    echo "dnf provider: unknown operation: $operation" >&2
    exit 1
    ;;
esac
