recipe_bin() {
    echo install-tl
}

recipe_install() {
    local permalink='https://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet/install-tl-unx.tar.gz'
    mkdir -p ~/.local/share/install-tl
    curl '-#L' "$permalink" | tar -xzC ~/.local/share/install-tl/ --strip 1
    cat <<EOF >~/.local/bin/install-tl
#!/bin/bash

if !(perl -e "use File::Find" 2>&1 >/dev/null); then
    echo "Please install perl-File-Find for this to work."
    exit 1
fi

if [[ \$UID -ne 0 ]]; then
    echo "Please run this script as root:

sudo \$0"
    exit 1
fi

pushd $HOME/.local/share/install-tl
./install-tl "\$@"
popd
EOF
    chmod +x ~/.local/bin/install-tl
}

# example invocation
#
# $ sudo ./install-tl --paper=letter --texdir=/usr/local/texlive/2023
#
#
#
# emacs flatpak usage
#
# $ sudo flatpak override org.gnu.emacs --filesystem=/var/usrlocal
# $ (setq exec-path (append exec-path '("/var/usrlocal/texlive/2023/bin/x86_64-linux/")))
#
