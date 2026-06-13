#!/bin/bash
# which i3

if [[ ! -e $HOME/.gestures ]]; then
    curl -so $HOME/.gestures https://raw.githubusercontent.com/bulletmark/libinput-gestures/master/libinput-gestures
fi

cat <<'EOF' >$HOME/.config/.gestures.conf
gesture swipe up bash -c "i3-msg workspace $(($(i3-msg -t get_workspaces | sed 's/^.*num\":\([1-9]\),.*focused\":true.*$/\1/g') + 1))"
gesture swipe down i3-msg workspace prev
EOF
