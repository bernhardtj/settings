#!/usr/bin/env bash
# test "$XDG_CURRENT_DESKTOP" = GNOME
echo "Setting up GNOME" && tail -n+5 ${BASH_SOURCE[0]} | dconf load /
exit

[org/gnome/desktop/app-folders]
folder-children=['']

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

[org/gnome/mutter]
workspaces-only-on-primary=true

[org/gnome/shell]
enabled-extensions=['settings-main@localhost', 'places-menu@gnome-shell-extensions.gcampax.github.com']

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0]
binding='<Super>Return'
command='kitty -1'
name='kitty'

[org/gnome/desktop/wm/keybindings]
move-to-workspace-1=['<Shift><Super>1']
move-to-workspace-2=['<Shift><Super>2']
move-to-workspace-3=['<Shift><Super>3']
move-to-workspace-4=['<Shift><Super>4']
switch-to-workspace-1=['<Super>1']
switch-to-workspace-2=['<Super>2']
switch-to-workspace-3=['<Super>3']
switch-to-workspace-4=['<Super>4']
