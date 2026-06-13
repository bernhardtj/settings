recipe_bin() {
    echo texlab
}

recipe_install() {
    _get_from_github latex-lsp/texlab texlab-x86_64-linux.tar.gz z 'texlab --version' 'install -Dm755 texlab $HOME/.local/bin/texlab'
}
