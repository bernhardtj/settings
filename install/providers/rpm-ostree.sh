#!/usr/bin/env bash
set -euo pipefail

operation="${1:-}"
[[ $# -gt 0 ]] && shift || true

if ! command -v rpm-ostree >/dev/null 2>&1; then
    echo "rpm-ostree provider: rpm-ostree is not available" >&2
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
    rpm -q "$1" >/dev/null 2>&1
}

missing_packages() {
    local package
    for package in "$@"; do
        if package_installed "$package"; then
            echo "rpm-ostree provider: already installed: $package" >&2
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
            echo "rpm-ostree provider: already absent: $package" >&2
        fi
    done
}

karg_present() {
    rpm-ostree kargs 2>/dev/null | tr ' ' '\n' | grep -Fxq "$1"
}

missing_kargs() {
    local arg
    for arg in "$@"; do
        if karg_present "$arg"; then
            echo "rpm-ostree provider: kernel arg already present: $arg" >&2
        else
            printf '%s\n' "$arg"
        fi
    done
}

prepare_transaction() {
    killall -9 gnome-software >/dev/null 2>&1 || true
    rpm-ostree cancel >/dev/null 2>&1 || true
}

case "$operation" in
install)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(missing_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "rpm-ostree provider: nothing to install" >&2
        exit 0
    }
    prepare_transaction
    run_as_root rpm-ostree install --idempotent --allow-inactive "${packages[@]}"
    ;;
remove)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(installed_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "rpm-ostree provider: nothing to remove" >&2
        exit 0
    }
    prepare_transaction
    run_as_root rpm-ostree override remove "${packages[@]}"
    ;;
kargs)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t missing < <(missing_kargs "$@")
    [[ ${#missing[@]} -gt 0 ]] || {
        echo "rpm-ostree provider: no kernel args to add" >&2
        exit 0
    }
    args=()
    for arg in "${missing[@]}"; do
        args+=(--append-if-missing="$arg")
    done
    prepare_transaction
    run_as_root rpm-ostree kargs "${args[@]}"
    ;;
*)
    echo "rpm-ostree provider: unknown operation: $operation" >&2
    exit 1
    ;;
esac
