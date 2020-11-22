#!/bin/bash

set -e

echo 'settings/apply -v && exit' >"$HOME/.zshrc"

pkexec bash <<EOF
rpm-ostree cancel &&
rpm-ostree reset &&
rpm-ostree update &&
rpm-ostree override remove sudo &&
rpm-ostree install zsh ImageMagick &&
sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd
EOF

reboot
