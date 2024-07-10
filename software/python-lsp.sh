recipe_bin() {
    echo pyright
    echo pyright-langserver
    echo jedi-language-server
}

recipe_install() {
    npm install -g pyright
    pipx install -f jedi-language-server
}
