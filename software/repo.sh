recipe_bin() {
    echo repo
}

recipe_install() {
    curl '-#Lo' ~/.local/bin/repo https://storage.googleapis.com/git-repo-downloads/repo
}
