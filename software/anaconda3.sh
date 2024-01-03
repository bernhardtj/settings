recipe_bin() {
    echo conda
}

recipe_install() {
    curl '-#Lo' anaconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
    bash anaconda.sh -bfp ~/anaconda3
    ln -sf "$HOME/anaconda3/bin/conda" "$HOME/.local/bin/conda"
}
