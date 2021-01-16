recipe_bin() {
    echo shfmt
}

recipe_install() {
    URL="https://github.com/mvdan/sh/releases"
    VERSION=$(curl -s "$URL/latest" | sed 's/.*tag\/\(.*\)".*/\1/g')
    curl '-#Lo' $HOME/.local/bin/shfmt "$URL"/download/"$VERSION"/shfmt_"$VERSION"_linux_amd64
}
