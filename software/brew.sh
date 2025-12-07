recipe_bin() {
    echo brew
}

recipe_install() {
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    cat <<'EOF' >"$HOME/.local/bin/brew"
#!/bin/bash
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
brew "$@"
EOF
    chmod +x "$HOME/.local/bin/brew"
}
