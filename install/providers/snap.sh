#!/usr/bin/env bash
set -euo pipefail

operation="${1:-}"
[[ $# -gt 0 ]] && shift || true

if ! command -v snap >/dev/null 2>&1; then
    echo "snap provider: snap is not installed" >&2
    exit 1
fi

run_as_root() {
    if [[ $UID -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

package_installed() {
    snap list "$1" >/dev/null 2>&1
}

missing_packages() {
    local package
    for package in "$@"; do
        if package_installed "$package"; then
            echo "snap provider: already installed: $package" >&2
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
            echo "snap provider: already absent: $package" >&2
        fi
    done
}

case "$operation" in
install)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(missing_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "snap provider: nothing to install" >&2
        exit 0
    }
    run_as_root snap install "${packages[@]}"
    ;;
install-classic)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(missing_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "snap provider: nothing to install" >&2
        exit 0
    }
    run_as_root snap install --classic "${packages[@]}"
    ;;
remove)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(installed_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "snap provider: nothing to remove" >&2
        exit 0
    }
    run_as_root snap remove "${packages[@]}"
    ;;
*)
    echo "snap provider: unknown operation: $operation" >&2
    exit 1
    ;;
esac
