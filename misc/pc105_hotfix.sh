cat <<EOF >/etc/udev/hwdb.d/90-pc105-to-pc104.hwdb
evdev:atkbd:dmi:*
KEYBOARD_KEY_56=backslash
EOF
