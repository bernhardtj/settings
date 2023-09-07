recipe_bin() {
    echo pyright
    echo pyright-langserver
}

recipe_install() {
    npm install -g pyright
}
