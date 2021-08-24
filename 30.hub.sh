#!/bin/bash
# test -f "$HOME/.config/gh/hosts.yml"
cat <<EOF >"$HOME/.config/hub"
$(sed -z 's/    /  /g;s/:\n./:\n-/g' ~/.config/gh/hosts.yml)
  protocol: https
EOF
