#!/usr/bin/env bash
# [ $XDG_CURRENT_DESKTOP = Hyprland ]

echo "Setting up MATE / i3"
gsettings set org.gnome.desktop.interface document-font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 11'
gsettings set org.gnome.desktop.interface gtk-theme 'Adapta-Eta'
gsettings set org.gnome.desktop.interface icon-theme 'menta'
gsettings set org.gnome.desktop.interface monospace-font-name 'Fira Code 12'
gsettings set org.mate.panel.menubar icon-name 'fedora-logo-icon'

dconf load / <<EOF
[org/mate/panel/general]
object-id-list=['menu-bar', 'volume-control', 'notification-area', 'clock', 'window-list', 'workspace-switcher']
[org/mate/panel/objects/window-list]
position=0
[org/mate/panel/toplevels/top/background]
color='rgba(255,255,255,0)'
type='color'
[org/mate/panel/toplevels/bottom/background]
color='rgba(255,255,255,0)'
type='color'
EOF

# for flatpaks
if [[ ! -e $HOME/.themes/Adapta-Eta ]]; then
    if [[ -e /usr/share/themes/Adapta-Eta ]]; then
        mkdir -p $HOME/.themes
        cp -r /usr/share/themes/Adapta-Eta $HOME/.themes/Adapta-Eta
    fi
fi
