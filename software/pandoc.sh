recipe_bin() {
    echo pandoc
}

recipe_install() {
    _get_from_github jgm/pandoc pandoc-VER-linux-amd64.tar.gz 'z --strip 1' 'pandoc --version | head -n1'
}
