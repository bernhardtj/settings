#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/lib/install.sh"

target_user="${SETTINGS_TARGET_USER:-${SUDO_USER:-${USER:-$(id -un)}}}"
zsh_path="$(grep '/zsh$' /etc/shells | tail -n 1 || true)"
if [[ -z $zsh_path ]]; then
    echo "set-zsh-shell: no zsh entry found in /etc/shells" >&2
    exit 1
fi

current_shell="$(getent passwd "$target_user" | awk -F: '{ print $7 }' || true)"
if [[ -z $current_shell ]]; then
    echo "set-zsh-shell: user not found: $target_user" >&2
    exit 1
fi

if [[ $current_shell == "$zsh_path" ]]; then
    echo "set-zsh-shell: $target_user already uses $zsh_path"
    exit 0
fi

settings_run chsh -s "$zsh_path" "$target_user"
