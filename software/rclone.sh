recipe_bin() {
    echo rclone
}

recipe_install() {
    curl '-#LO' https://downloads.rclone.org/rclone-current-linux-amd64.zip
    unzip *.zip
    install -Dm755 ./*/rclone $HOME/.local/bin/rclone
    install -Dm644 ./*/rclone.1 $HOME/.local/share/man/man1/
}
