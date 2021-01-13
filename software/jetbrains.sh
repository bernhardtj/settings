recipe_bin() {
    echo jetbrains-toolbox
}

recipe_install() {
    URL='https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release'
    prefix=$(mktemp -d)
    eval "$(
        python <<EOF
import json
resp = json.loads(r"""$(curl -s "$URL")""")['TBA'][0]
print(f"curl '-#L' {resp['downloads']['linux']['link']} | tar xzC $prefix --strip 1;")
EOF
    )"
    install -Dm755 "$prefix/jetbrains-toolbox" "$HOME/.local/bin/jetbrains-toolbox"
}
