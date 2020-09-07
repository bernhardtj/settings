#!/bin/bash
# test "$XDG_CURRENT_DESKTOP" = GNOME

rm -rf ~/.local/share/gnome-shell/extensions/settings@localhost

XDG_DATA_DIRS='' gnome-extensions create \
--name='Settings for GNOME' \
--description='GNOME Shell javascript tweaks, per Settings' \
--uuid="settings@localhost" \
2> /dev/null

rm ~/.local/share/gnome-shell/extensions/settings@localhost/extension.js

