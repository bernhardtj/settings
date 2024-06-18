recipe_bin() {
    echo pipx
}

recipe_install() {
    #python -m ensurepip --upgrade --default-pip --user
    python -m venv venv
    venv/bin/python -m pip install pipx
    venv/bin/pipx install pipx --force
}
