#!/usr/bin/env bash
# test "$XDG_CURRENT_DESKTOP" = GNOME
echo "Setting up GNOME" && tail -n+5 ${BASH_SOURCE[0]} | dconf load /
exit

[org/gnome/desktop/input-sources]
xkb-options=['caps:ctrl_modifier']

[org/gnome/desktop/interface]
monospace-font-name='Fira Code 12'

[org/gnome/desktop/peripherals/touchpad]
tap-to-click=true

[org/gnome/desktop/peripherals/trackball]
scroll-wheel-emulation-button=2

[org/gnome/desktop/wm/preferences]
auto-raise=true
auto-raise-delay=0
focus-mode='mouse'

[org/gnome/shell]
enabled-extensions=['settings@localhost', 'places-menu@gnome-shell-extensions.gcampax.github.com']

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>Return'
command='.local/bin/kitty -1'
name='kitty'
