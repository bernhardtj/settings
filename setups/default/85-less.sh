#!/bin/bash
# test -x /usr/bin/lesspipe.sh
cat <<'EOF' >~/.lessfilter
#!/usr/bin/sh
case "$1" in
*.md | *.markdown | *.mdown | *.mkd)
    command -v glow >/dev/null 2>&1 || exit 1
    unset NO_COLOR
    export CLICOLOR_FORCE=1
    exec glow --style "${GLAMOUR_STYLE:-dark}" "$1"
    ;;
*.odt | *.ods | *.odp)
    command -v flatpak >/dev/null 2>&1 || exit 1
    flatpak info org.libreoffice.LibreOffice >/dev/null 2>&1 || exit 1
    exec flatpak run org.libreoffice.LibreOffice --cat "$1"
    ;;
*) exit 1
esac
EOF
chmod +x ~/.lessfilter
