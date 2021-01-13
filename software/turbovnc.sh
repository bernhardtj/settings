recipe_bin() {
    echo vncviewer
}

recipe_install() {
    URL="https://github.com/turbovnc/turbovnc/releases"
    VERSION=$(curl -s "$URL/latest" | sed 's/.*tag\/\(.*\)".*/\1/g')
    cd $(mktemp -d)
    curl '-#L' "https://sourceforge.net/projects/turbovnc/files/$VERSION/turbovnc-$VERSION.x86_64.rpm" | rpm2cpio | cpio -id
    rm -rf ~/.local/share/TurboVNC
    mv opt/TurboVNC ~/.local/share
    cat <<'EOF' >~/.local/bin/vncviewer
JAVA_HOME="$(find $HOME/.local/share/JetBrains -type d -name jbr -print -quit)" $HOME/.local/share/TurboVNC/bin/vncviewer "$@"
EOF
    chmod +x ~/.local/bin/vncviewer
}
