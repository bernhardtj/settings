#!/usr/bin/env bash
set -euo pipefail

operation="${1:-}"
[[ $# -gt 0 ]] && shift || true

find_brew() {
    if command -v brew >/dev/null 2>&1; then
        command -v brew
        return
    fi
    if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
        echo /home/linuxbrew/.linuxbrew/bin/brew
        return
    fi
    if [[ -x "$HOME/.linuxbrew/bin/brew" ]]; then
        echo "$HOME/.linuxbrew/bin/brew"
        return
    fi
    return 1
}

brew_bin="$(find_brew)" || {
    echo "brew provider: brew is not installed; run 'bin/settings-software install brew' first" >&2
    exit 1
}

package_installed() {
    "$brew_bin" list --formula "$1" >/dev/null 2>&1 ||
        "$brew_bin" list --cask "$1" >/dev/null 2>&1
}

missing_packages() {
    local package
    for package in "$@"; do
        if package_installed "$package"; then
            echo "brew provider: already installed: $package" >&2
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
            echo "brew provider: already absent: $package" >&2
        fi
    done
}

case "$operation" in
install)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(missing_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "brew provider: nothing to install" >&2
        exit 0
    }
    "$brew_bin" install "${packages[@]}"
    ;;
remove)
    [[ $# -gt 0 ]] || exit 0
    mapfile -t packages < <(installed_packages "$@")
    [[ ${#packages[@]} -gt 0 ]] || {
        echo "brew provider: nothing to remove" >&2
        exit 0
    }
    "$brew_bin" uninstall "${packages[@]}"
    ;;
*)
    echo "brew provider: unknown operation: $operation" >&2
    exit 1
    ;;
esac
