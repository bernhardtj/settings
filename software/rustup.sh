recipe_bin() {
    echo rustup-init
}

recipe_install() {
    curl -sLo "$HOME"/.local/bin/rustup-init sh.rustup.rs
    chmod +x "$HOME"/.local/bin/rustup-init
}
