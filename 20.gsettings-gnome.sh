#!/usr/bin/env bash
# type gnome-session >/dev/null 2>&1

echo "Setting up GNOME"
gsettings set org.gnome.desktop.wm.preferences focus-mode mouse
gsettings set org.gnome.desktop.wm.preferences auto-raise true
gsettings set org.gnome.desktop.wm.preferences auto-raise-delay 0
gsettings set org.gnome.desktop.interface monospace-font-name "Fira Code 12"
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
