recipe_bin() {
    cat <<EOF
raco
racket
EOF
}

recipe_install() {
    VER="$(curl -sL https://download.racket-lang.org/releases | sed -n '/td/{s/^.*href="\(.*\)"><img.*$/\1/g;p}' | head -n1)"
    curl '-#L' "https://download.racket-lang.org/releases/$VER/installers/racket-minimal-$VER-x86_64-linux-cs.tgz" | tar -xzC "$HOME/.local" --strip 1
    sed -i '3i export SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt' "$HOME/.local/bin/raco"
}
