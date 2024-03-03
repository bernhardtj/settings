#!/bin/bash
# false

echo 'hide_window_decorations yes' >>~/.config/kitty/kitty.conf

cat <<EOF >.config/gtk-3.0/gtk.css
window.ssd separator:first-child + headerbar:backdrop,
window.ssd separator:first-child + headerbar,
window.ssd headerbar:first-child:backdrop,
window.ssd headerbar:first-child,
window.ssd headerbar:last-child:backdrop,
window.ssd headerbar:last-child,
window.ssd stack headerbar:first-child:backdrop,
window.ssd stack headerbar:first-child,
window.ssd stack headerbar:last-child:backdrop,
window.ssd stack headerbar:last-child,
window.ssd decoration,
window.ssd headerbar.titlebar {
    border-radius: 0;
}

window.ssd headerbar * {
    margin-top: -100px;
}

window.ssd headerbar.titlebar,
window.ssd headerbar.titlebar button.titlebutton {
    border: none;
    font-size: 0;
    height: 0;
    margin: 0;
    max-height: 0;
    min-height: 0;
    padding: 0;
}
EOF

dconf load / <<EOF
[org/gnome/desktop/wm/preferences]
auto-raise=true
auto-raise-delay=0
focus-mode='mouse'
EOF
