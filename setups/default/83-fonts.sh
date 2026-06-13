#!/bin/bash
# [ ! -f /home/jj/.local/share/fonts/FiraCodeNerdFont-Regular.ttf ]

main() {
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    source "$repo_root/lib/software.sh"
    target="$(mktemp)"
    curl -sLo "$target" "$(_get_dl_link_from_github ryanoasis/nerd-fonts FiraCode.zip)"
    unzip -d ~/.local/share/fonts "$target" <<<A
    echo
}
main 2>&1
