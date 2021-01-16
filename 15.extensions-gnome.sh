#!/usr/bin/env bash
# test "$XDG_CURRENT_DESKTOP" = GNOME

if [[ ! -f "$HOME/.local/share/gnome-shell/extensions/gnomesome@chwick.github.com/extension.js" ]]; then
    mkdir -p "$HOME/.local/share/gnome-shell/extensions/gnomesome@chwick.github.com/"
    curl -sLo /tmp/gnomesome.zip "https://extensions.gnome.org/download-extension/gnomesome%40chwick.github.com.shell-extension.zip?version_tag=$(curl -s https://extensions.gnome.org/extension/1268/gnomesome/ | grep data-versions | sed 's/.*: \(.*\)\, \&q.*$/\1/g')"
    unzip -od "$HOME/.local/share/gnome-shell/extensions/gnomesome@chwick.github.com/" /tmp/gnomesome.zip
fi

dconf load / <<EOF
[org/gnome/shell/extensions/gnomesome/prefs]
default-layout='vertical'
launch-terminal='$HOME/.local/bin/kitty -1'
outer-gaps=10
show-indicator=false
EOF

rm -rf ~/.local/share/gnome-shell/extensions/settings@localhost
XDG_DATA_DIRS='' gnome-extensions create \
    --name='Settings for GNOME' \
    --description='GNOME Shell javascript tweaks, per Settings' \
    --uuid="settings@localhost" \
    2>/dev/null

gsettings set org.gnome.shell enabled-extensions "['gnomesome@chwick.github.com', 'places-menu@gnome-shell-extensions.gcampax.github.com', 'settings@localhost']"
