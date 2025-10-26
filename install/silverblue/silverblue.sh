#!/bin/bash
#
# bluefin cmd
# rpt rebase ostree-unverified-registry:ghcr.io/ublue-os/silverblue-main:gts
#
#
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

source /etc/os-release
if [[ $ID == bluefin ]]; then
    pkgs=(
        "${pkgs_deps_bluefin[@]}"
    )

else
    pkgs=(
        rpmfusion-free-release
        rpmfusion-nonfree-release
        "${pkgs_base[@]}"
        "${pkgs_deps[@]}"
        "${pkgs_tools[@]}"
        "${pkgs_drivers[@]}"
    )

    if [[ ! -f /etc/yum.repos.d/rpmfusion-free.repo ]]; then
        get_rpm "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
        get_rpm "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    fi

    if [[ ! -f /etc/yum.repos.d/docker-ce.repo ]]; then
        curl -sLo '/etc/yum.repos.d/docker-ce.repo' 'https://download.docker.com/linux/fedora/docker-ce.repo'
    fi

fi

rpm-ostree update "${pkgs[@]/#/--install=}"

rpm-ostree override remove ptyxis gnome-tour yelp

# openh264 >f40
rpm-ostree override remove noopenh264 --install openh264 --install mozilla-openh264

sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd

sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf
systemctl enable --now rpm-ostreed-automatic.timer

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo

flatpak remote-modify --enable flathub

# flatpak install --reinstall -y flathub $(curl https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/flatpaks/system-flatpaks.list) $(curl https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/flatpaks/system-flatpaks-dx.list)
# brew bundle --file <( curl -fSsL https://raw.githubusercontent.com/ublue-os/bluefin/refs/heads/main/brew/bluefin-ai.Brewfile)

reboot
