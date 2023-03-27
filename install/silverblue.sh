#!/bin/bash

if [[ $UID != 0 ]]; then
    printf "settings/apply -v; . ~/.zshrc" >~/.zshrc
    pkexec bash "$(realpath "${BASH_SOURCE[0]}")"
    exit
fi

set -ex

killall -9 gnome-software
rpm-ostree cancel

rpm-ostree reset

rpm-ostree install -A https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

rpm-ostree update \
    --install=ImageMagick \
    --install=ShellCheck \
    --install=android-tools \
    --install=cockpit \
    --install=cockpit-composer \
    --install=cockpit-file-sharing \
    --install=cockpit-kdump \
    --install=cockpit-machines \
    --install=cockpit-navigator \
    --install=cockpit-networkmanager \
    --install=cockpit-ostree \
    --install=cockpit-packagekit \
    --install=cockpit-podman \
    --install=cockpit-selinux \
    --install=cockpit-session-recording \
    --install=cockpit-sosreport \
    --install=cockpit-storaged \
    --install=dnf \
    --install=edk2-ovmf \
    --install=fira-code-fonts \
    --install=g++ \
    --install=gh \
    --install=gimp \
    --install=gnome-text-editor \
    --install=gstreamer1-plugin-openh264 \
    --install=hub \
    --install=inkscape \
    --install=kitty \
    --install=libvirt-daemon-config-network \
    --install=libvirt-daemon-kvm \
    --install=mozilla-openh264 \
    --install=nc \
    --install=nmap \
    --install=p7zip-plugins \
    --install=pandoc \
    --install=python3-devel \
    --install=python3-pygments \
    --install=qemu-kvm \
    --install=qemu-user-static \
    --install=rclone \
    --install=ripgrep \
    --install=rlwrap \
    --install=rpm-build \
    --install=rpm-devel \
    --install=rpmdevtools \
    --install=rpmlint \
    --install=screen \
    --install=shfmt \
    --install=swtpm-tools \
    --install=vim-enhanced \
    --install=virt-install \
    --install=virt-manager \
    --install=zsh

rpm-ostree override remove gnome-terminal gnome-terminal-nautilus gnome-tour yelp

sed -i 's/\(.*1000.*\)bash/\1zsh/g' /etc/passwd

sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf
systemctl enable --now rpm-ostreed-automatic.timer

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak remote-add --if-not-exists gnome-nightly https://nightly.gnome.org/gnome-nightly.flatpakrepo

#flatpak remove --all -y

reboot
