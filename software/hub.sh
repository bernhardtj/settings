recipe_bin() {
    cat <<EOF
gh
hub
EOF
}

recipe_install() {
    _get_from_github github/hub hub-linux-amd64-VER.tgz z 'hub --version | tail -n1' 'prefix=$HOME/.local ./hub-linux-amd64-VER/install'
    _get_from_github cli/cli gh_VER_linux_amd64.tar.gz 'z --strip 1' 'gh --version | head -n1'
}
