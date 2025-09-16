recipe_bin() {
    echo jetbrains-toolbox
}

recipe_install() {
    mkdir -p "$HOME/.local/share/JetBrains/Toolbox/toolbox-app"
    URL='https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release'
    eval "$(
        python <<EOF
import json
resp = json.loads(r"""$(curl -s "$URL")""")['TBA'][0]
print(f"curl '-#L' {resp['downloads']['linux']['link']} | tar xzC '$HOME/.local/share/JetBrains/Toolbox/toolbox-app' --strip 1;")
EOF
    )"
    ln -sf "$HOME/.local/share/JetBrains/Toolbox/toolbox-app/bin/jetbrains-toolbox" "$HOME/.local/bin/jetbrains-toolbox"
}
