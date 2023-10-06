#!/usr/bin/env bash
# test "$XDG_CURRENT_DESKTOP" = MATE

echo "Setting up MATE / i3"
gsettings set org.mate.applications-terminal exec "kitty -1"
gsettings set org.mate.background show-desktop-icons false
gsettings set org.mate.caja.compact-view default-zoom-level 'larger'
gsettings set org.mate.caja.desktop font 'Cantarell 11'
gsettings set org.mate.caja.preferences default-folder-viewer 'list-view'
gsettings set org.mate.interface document-font-name 'Cantarell 11'
gsettings set org.mate.interface font-name 'Cantarell 11'
gsettings set org.mate.interface gtk-theme 'Adapta-Eta'
gsettings set org.mate.interface icon-theme 'menta'
gsettings set org.mate.interface monospace-font-name 'Fira Code 12'
gsettings set org.mate.Marco.general theme 'Adapta'
gsettings set org.mate.Marco.general titlebar-font 'Cantarell Bold 11'
gsettings set org.mate.NotificationDaemon theme 'slider'
gsettings set org.mate.peripherals-mouse cursor-theme 'Adwaita'
gsettings set org.mate.peripherals-touchpad natural-scroll true
gsettings set org.mate.peripherals-touchpad tap-to-click true
gsettings set org.mate.peripherals-touchpad two-finger-click 3
gsettings set org.mate.session.required-components windowmanager 'i3'
gsettings set org.mate.sound theme-name '__no_sounds'

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
[org/mate/desktop/keybindings/custom0]
action='kitty -1'
binding='<Mod4>Return'
name='kitty'
EOF

mkdir -p $HOME/.config/autostart
ln -sf /usr/share/applications/picom.desktop $HOME/.config/autostart

# for flatpaks
if [[ ! -e $HOME/.themes/Adapta-Eta ]]; then
    if [[ -e /usr/share/themes/Adapta-Eta ]]; then
        mkdir -p $HOME/.themes
        cp -r /usr/share/themes/Adapta-Eta $HOME/.themes/Adapta-Eta
    fi
fi
