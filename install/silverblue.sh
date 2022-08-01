#!/bin/bash

if [[ $UID != 0 ]]; then
    printf "settings/apply -v; . ~/.zshrc" >~/.zshrc
    pkexec bash "$(realpath "${BASH_SOURCE[0]}")"
    exit
fi

set -ex

rpm-ostree cancel
rpm-ostree reset
rpm-ostree update \
    --install=ImageMagick \
    --install=ShellCheck \
    --install=android-tools \
    --install=dnf \
    --install=evince \
    --install=g++ \
    --install=gimp \
    --install=gnome-console \
    --install=gnome-text-editor \
    --install=inkscape \
    --install=kitty \
    --install=nc \
    --install=nmap \
    --install=p7zip-plugins \
    --install=pandoc \
    --install=python3-devel \
    --install=python3-pygments \
    --install=rclone \
    --install=ripgrep \
    --install=rlwrap \
    --install=rpm-build \
    --install=rpm-devel \
    --install=rpmdevtools \
    --install=rpmlint \
    --install=screen \
    --install=shfmt \
    --install=vim-enhanced \
    --install=zsh

rpm-ostree override remove gnome-terminal gnome-terminal-nautilus

sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd

sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf
systemctl enable --now rpm-ostreed-automatic.timer

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo

flatpak remove --all -y

reboot
