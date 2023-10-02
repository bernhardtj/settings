#!/bin/bash

get_rpm() {
    curl -sL "$1" | rpm2cpio | cpio -idD /
}

if [[ $UID != 0 ]]; then
    printf "settings/apply -v; . ~/.zshrc" >~/.zshrc
    pkexec bash "$(realpath "${BASH_SOURCE[0]}")"
    exit
fi

set -ex

source "$(dirname "${BASH_SOURCE[0]}")"/groups-fedora.sh
source "$(dirname "${BASH_SOURCE[0]}")"/drivers.sh

killall -9 gnome-software || true
rpm-ostree cancel

rpm-ostree reset

pkgs=(
    rpmfusion-free-release
    rpmfusion-nonfree-release
    "${pkgs_base[@]}"
    "${pkgs_deps[@]}"
    "${pkgs_drivers[@]}"
)

if [[ ! -f /etc/yum.repos.d/rpmfusion-free.repo ]]; then
    get_rpm "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    get_rpm "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
fi

if [[ ! -f /etc/yum.repos.d/TurboVNC.repo ]]; then
    curl -sLo '/etc/yum.repos.d/TurboVNC.repo' 'https://turbovnc.org/pmwiki/uploads/Downloads/TurboVNC.repo'
fi

rpm-ostree update "${pkgs[@]/#/--install=}"

rpm-ostree override remove gnome-terminal gnome-terminal-nautilus gnome-tour yelp

sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd

sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf
systemctl enable --now rpm-ostreed-automatic.timer

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo

flatpak remote-modify --enable flathub

reboot
