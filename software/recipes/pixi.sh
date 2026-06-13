recipe_bin() {
    echo pixi
}

recipe_install() {
    sh <(curl -LsSf https://pixi.sh/install.sh) >/dev/null 2>&1
    ln -sf "$HOME"/.{pixi,local}/bin/pixi
}
