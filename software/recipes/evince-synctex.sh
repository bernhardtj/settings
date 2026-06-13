recipe_bin() {
    echo evince-synctex
}

recipe_install() {
    curl -sLo "$HOME/.local/bin/evince-synctex" https://raw.githubusercontent.com/latex-lsp/evince-synctex/master/evince_synctex.py
}
