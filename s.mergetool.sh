.local/bin/auto-mergetool
#!/bin/bash

LOCAL=$1
REMOTE=$2
BASE=$3
MERGED=$4

if [[ -f ~/.local/bin/pycharm ]]; then
    exec ~/.local/bin/pycharm merge "$LOCAL" "$REMOTE" "$BASE" "$MERGED"
elif flatpak list | grep org.gnome.meld >/dev/null 2>&1; then
    exec flatpak run --file-forwarding org.gnome.meld "@@" "$LOCAL" "@@" "@@" "$BASE" "@@" "@@" "$REMOTE" "@@" --output "@@" "$MERGED" "@@"
else
    echo "auto mergetool: did not find pycharm or meld"
fi
