recipe_bin() {
    echo jetbrains-toolbox
}

recipe_install() {
    URL='https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release'
    eval "$(
        python <<EOF
import json
resp = json.loads(r"""$(curl -s "$URL")""")['TBA'][0]
print(f"curl '-#L' {resp['downloads']['linux']['link']} | tar xz --strip 1;")
EOF
    )"
    install -Dm755 "./jetbrains-toolbox" "$HOME/.local/bin/jetbrains-toolbox"
}
