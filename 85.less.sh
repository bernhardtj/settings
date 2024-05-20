#!/bin/bash
# test -e /usr/bin/lesspipe.sh
cat <<EOF >~/.lessfilter
#!/usr/bin/sh
case "\$1" in
$(pygmentize -L | sed -n 's/^.*(filenames \(.*\)).*$/\1/gp' | head -c-1 | tr ',\n' '|')) pygmentize -f terminal256 -O style=native -g "\$1"; exit \$? ;;
*.odt|*.ods|*.odp) flatpak run org.libreoffice.LibreOffice --cat "\$1"; exit \$? ;;
*) exit 1
esac
EOF
chmod +x ~/.lessfilter
