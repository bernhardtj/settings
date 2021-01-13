recipe_bin() {
    cat <<EOF
pygmentize
pcat
pless
EOF
}

recipe_install() {
    pip install --user --force-reinstall pygments
    echo 'pygmentize -f terminal256 -O style=native -g "$@"' >$HOME/.local/bin/pcat
    echo "LESSOPEN='|(pygmentize -f terminal256 -O style=native -g %s)' less" '"$@"' >$HOME/.local/bin/pless
}
