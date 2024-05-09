#!/usr/bin/env bash
# true
# software in the home folder

ln -sf "$(dirname "${BASH_SOURCE[0]}")/software-mono.sh" "$HOME/.local/bin/software-update"
bash "$(dirname "${BASH_SOURCE[0]}")/software-mono.sh" --setup
