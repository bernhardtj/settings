recipe_bin() {
    echo shellcheck
}

recipe_install() {
    _get_from_github koalaman/shellcheck shellcheck-vVER.linux.x86_64.tar.xz 'J --strip 1' 'shellcheck --version | /bin/grep version -m 1' 'install -Dm755 shellcheck $HOME/.local/bin/shellcheck'
}
