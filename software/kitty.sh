recipe_bin() {
    echo kitty
}

recipe_install() {
    _get_from_github kovidgoyal/kitty kitty-VER-x86_64.txz J 'kitty --version'
}
