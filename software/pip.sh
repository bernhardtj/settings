recipe_bin() {
    echo pip
}

recipe_install() {
    python -m ensurepip --upgrade --default-pip --user
}
