recipe_bin() {
    cat <<EOF
vi
nvim
EOF
}

recipe_install() {
    _get_from_github neovim/neovim nvim-linux64.tar.gz 'z --strip 1' 'nvim --version | head -n1'
    ln -sf $HOME/.local/bin/{nvim,vi}
}
