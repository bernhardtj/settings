recipe_bin() {
    echo payload-dumper-go
}

recipe_install() {
    _get_from_github ssut/payload-dumper-go payload-dumper-go_VER_linux_amd64.tar.gz z 'echo payload-dumper-go $VERSION' 'install -Dm755 payload-dumper-go $HOME/.local/bin/payload-dumper-go'
}
