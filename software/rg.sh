recipe_bin() {
    echo rg
}

recipe_install() {
    _get_from_github burntsushi/ripgrep ripgrep-VER-x86_64-unknown-linux-musl.tar.gz z 'rg --version | head -n1' \
        'install -Dm755 */rg $HOME/.local/bin/rg; install -Dm644 */doc/rg.1 $HOME/.local/share/man/man1/rg.1'
}
