#!/bin/bash

set -e

echo 'settings/apply -v && exit' >"$HOME/.zshrc"

pkexec bash <<EOF
rpm-ostree cancel &&
rpm-ostree reset &&
rpm-ostree update &&
rpm-ostree override remove sudo sudo-python-plugin &&
rpm-ostree install zsh ImageMagick make gcc g++ &&
sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd &&
sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf &&
systemctl enable rpm-ostreed-automatic.timer &&
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
EOF

reboot
