recipe_bin() {
    echo tlmgr
}

recipe_install() {
    local prefix="$HOME/.local/share/texlive"

    cat <<EOF >"$HOME/.local/bin/tlmgr"
#!/bin/bash
/bin/tail -n+4 \${BASH_SOURCE[0]}
exit 1
==========> install-tl
"$(install-tl --paper=letter --texdir="$prefix" --scheme=scheme-infraonly --no-interaction 2>&1)"
==========> tlmgr
using tlmgr path at <"$(find "$prefix" -name tlmgr)">
"$( ("$(find "$prefix" -name tlmgr)" option sys_bin "$HOME/.local/bin") 2>&1 || echo 'TLERROR')"
"$( ("$(find "$prefix" -name tlmgr)" option sys_man "$HOME/.local/man") 2>&1 || echo 'TLERROR')"
"$( ("$(find "$prefix" -name tlmgr)" option sys_info "$HOME/.local/info") 2>&1 || echo 'TLERROR')"

***There were errors running install-tl. Please see above.***
EOF

    if ! grep TLERROR "$HOME/.local/bin/tlmgr" >/dev/null 2>&1; then
        rm -f "$HOME/.local/bin/tlmgr"
        "$(find "$prefix" -name tlmgr)" path add tlmgr
    fi
}
