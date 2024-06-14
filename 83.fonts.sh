#!/bin/bash
# [ ! -f /home/jj/.local/share/fonts/FiraCodeNerdFont-Regular.ttf ]

main() {
    source "$(dirname "${BASH_SOURCE[0]}")/software-mono.sh"
    target="$(mktemp)"
    curl -sLo "$target" "$(_get_dl_link_from_github ryanoasis/nerd-fonts FiraCode.zip)"
    unzip -d ~/.local/share/fonts "$target" <<<A
    echo
}
main 2>&1
