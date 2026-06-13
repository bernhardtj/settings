#!/usr/bin/env bash
# true
# software in the home folder

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

mkdir -p "$HOME/.local/bin"
ln -sf "$repo_root/bin/settings-software" "$HOME/.local/bin/software-update"
"$repo_root/bin/settings-software" setup-shims
