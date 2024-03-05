recipe_bin() {
    cat <<EOF
gh
EOF
}

recipe_install() {
    _get_from_github cli/cli gh_VER_linux_amd64.tar.gz 'z --strip 1' 'gh --version | head -n1'
}
