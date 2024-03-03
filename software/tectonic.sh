recipe_bin() {
    echo tectonic
}

recipe_install() {
    curl -sL https://drop-sh.fullyjustified.net | bash
    mv tectonic "$HOME"/.local/bin
}
