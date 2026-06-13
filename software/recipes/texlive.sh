recipe_bin() {
    echo install-tl
}

recipe_install() {
    local permalink='https://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet/install-tl-unx.tar.gz'
    local prefix="$HOME/.local/share/install-tl"

    mkdir -p "$prefix"
    curl '-#L' "$permalink" | tar -xzC "$prefix" --strip 1
    cat <<EOF >~/.local/bin/install-tl
#!/bin/bash

if ! perl -e "use File::Find" >/dev/null 2>&1; then
    echo "Please install perl-File-Find for this to work."
    exit 1
fi

pushd $prefix && ./install-tl "\$@"
popd || exit
EOF
}
