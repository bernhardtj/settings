recipe_bin() {
    echo auctex
}

recipe_install() {
    podman build -t auctex -f - <<EOF
from texlive/texlive:latest-with-cache
run apt update && apt install -y libunicode-linebreak-perl libyaml-tiny-perl libfile-homedir-perl auctex emacs-lucid hunspell && apt-get autoremove -qy --purge && rm -rf /var/lib/apt/lists/* && apt-get clean && rm -rf /var/cache/apt/
EOF
    cat <<'EOF' >$HOME/.local/bin/auctex
podman run --rm -it \
    -v /tmp/.X11-unix:/tmp/.X11-unix -e DISPLAY --security-opt=label=disable \
    -v "$HOME/.config/auctex:/root" \
    -v "$HOME/.local/share/fonts:/root/.local/share/fonts" \
    -v /var/home:/var/home -w "$(pwd)" auctex /usr/bin/emacs "$@"
EOF
    if [[ ! -e $HOME/.local/share/applications/auctex.desktop ]]; then
        mkdir -p $HOME/.local/share/icons/hicolor/{scalable,symbolic}/apps
        curl '-sLo' $HOME/.local/share/icons/hicolor/scalable/apps/auctex.svg https://gitlab.gnome.org/GNOME/gnome-latex/-/raw/master/data/icons/org.gnome.gnome-latex.svg
        curl '-sLo' $HOME/.local/share/icons/hicolor/symbolic/apps/auctex-symbolic.svg https://gitlab.gnome.org/GNOME/gnome-latex/-/raw/master/data/icons/org.gnome.gnome-latex-symbolic.svg
        curl '-sL' https://gitlab.gnome.org/GNOME/gnome-latex/-/raw/master/data/org.gnome.gnome-latex.desktop.in | sed "s/GNOME LaTeX/AUCTeX/g;s/Icon=.*latex/Icon=auctex/g;s,gnome-latex,$HOME/.local/bin/auctex,g" | tr -d '_' >"$HOME/.local/share/applications/auctex.desktop"
    fi
}
