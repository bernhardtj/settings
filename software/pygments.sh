recipe_bin() {
    cat <<EOF
pygmentize
EOF
}

recipe_install() {
    pip install --user --force-reinstall pygments
    rm -f "$HOME/.lessfilter"
}
