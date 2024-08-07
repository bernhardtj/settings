recipe_bin() {
    echo conda
}

recipe_install() {
    curl '-#Lo' anaconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    rm -rf "$HOME/anaconda3"
    echo 'Working...' && bash anaconda.sh -bfp ~/anaconda3 >/dev/null 2>&1
    rm -rf "$HOME/anaconda3/pkgs"
    ln -sf "$HOME/anaconda3/bin/conda" "$HOME/.local/bin/conda"
}
