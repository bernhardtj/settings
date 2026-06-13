recipe_bin() {
    echo ruffle
}

recipe_install() {
    VERSION="$(curl -s https://github.com/ruffle-rs/ruffle/releases | /bin/grep 'href="/ruffle-rs/ruffle/releases/tag' -m1 | sed 's,^.*tag/\(.*\)" d.*$,\1,g')"
    schema="$(curl -s "https://github.com/ruffle-rs/ruffle/releases/expanded_assets/$VERSION" | /bin/grep 'linux-x86' -m1 | sed 's,^.*/\(ruffle-nightly.*linux.*\)" rel.*$,\1,g')"
    _get_from_github ruffle-rs/ruffle "$schema" z 'ruffle --version' 'install -Dm755 ruffle $HOME/.local/bin/ruffle'
}
