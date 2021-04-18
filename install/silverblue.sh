#!/bin/bash

set -e

pkexec bash <<EOF
rpm-ostree cancel &&
rpm-ostree reset &&
rpm-ostree update &&
rpm-ostree install zsh ImageMagick make gcc g++ dnf &&
sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd &&
sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf &&
systemctl enable rpm-ostreed-automatic.timer &&
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
EOF

echo 'settings/apply -v && exit' >"$HOME/.zshrc"

reboot
