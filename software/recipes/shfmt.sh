recipe_bin() {
    echo shfmt
}

recipe_install() {
    URL="https://github.com/mvdan/sh/releases"
    VERSION="$(curl -v "$URL/latest" 2>&1 | /bin/grep location | sed 's,^.*tag/,,g' | tr -d '\r\n')"
    echo Found ver. "$VERSION"
    curl '-#Lo' "$HOME/.local/bin/shfmt" "$URL"/download/"$VERSION"/shfmt_"$VERSION"_linux_amd64
}
