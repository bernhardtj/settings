recipe_bin() {
    echo uv
}

recipe_install() {
    sh <(curl -LsSf https://astral.sh/uv/install.sh) -q
}
