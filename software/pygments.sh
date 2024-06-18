recipe_bin() {
    cat <<EOF
pygmentize
EOF
}

recipe_install() {
    pipx install -f pygments
    rm -f "$HOME/.lessfilter"
}
