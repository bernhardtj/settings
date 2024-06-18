recipe_bin() {
    echo poetry
}

recipe_install() {
    pipx install -f poetry
}
