recipe_bin() {
    echo chktex
}

recipe_install() {
    tlmgr install chktex >/dev/null 2>&1
    tlmgr path add chktex >/dev/null 2>&1
}
