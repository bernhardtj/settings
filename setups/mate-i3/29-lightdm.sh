#!/bin/bash
# false
sudo tee /etc/lightdm/lightdm-gtk-greeter.conf <<EOF
[greeter]
background = $(gsettings get org.mate.background picture-filename | tr -d "'")
theme-name = Adapta-Eta
icon-theme-name = menta
font-name = Cantarell 11
hide-user-image = true
clock-format = %a %h %e, %l:%M %p
indicators = ~host;~spacer;~clock;~spacer;~power
position = 31%,center 76%,center
EOF
