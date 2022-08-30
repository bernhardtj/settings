#!/bin/bash

set -ex

sudo dnf install -y \
    https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

cat <<EOF | while read line; do sudo dnf copr enable -y $line; done
gagbo/kitty-latest
nforro/i3-gaps
oleastre/fonts
EOF

sudo dnf install -y \
    "*fira-code*" \
    abiword \
    adapta-gtk-theme \
    compton \
    exa \
    git \
    git-extras \
    git-gui \
    gitk \
    gnumeric \
    gstreamer1-plugins-bad-nonfree \
    gvim \
    hub \
    i3-gaps \
    icecat \
    keepassxc \
    kitty \
    lightdm-gtk-greeter-settings \
    qt5-qtstyleplugins \
    quodlibet \
    rabbitvcs-caja \
    ripgrep \
    sylpheed \
    synapse \
    vlc \
    zeitgeist \
    zsh \
    "f2*backgrounds-*gnome" \
    "f2*backgrounds-*mate" \
    fedorainfinity-backgrounds \
    desktop-backgrounds-waves \
    solar-backgrounds \
    leonidas-backgrounds-lion \
    constantine-backgrounds \
    schroedinger-cat-backgrounds-extras-mate \
    schroedinger-cat-backgrounds-mate \
    heisenbug-backgrounds-extras-mate \
    heisenbug-backgrounds-mate \
    goddard-backgrounds-gnome \
    laughlin-backgrounds-extras-gnome \
    laughlin-backgrounds-gnome \
    lovelock-backgrounds-gnome \
    lovelock-backgrounds-stripes-gnome \
    verne-backgrounds-extras-gnome \
    verne-backgrounds-gnome \
    beefy-miracle-backgrounds-gnome \
    spherical-cow-backgrounds-extras-gnome \
    spherical-cow-backgrounds-gnome \
    schroedinger-cat-backgrounds-extras-gnome \
    schroedinger-cat-backgrounds-gnome \
    heisenbug-backgrounds-extras-gnome \
    heisenbug-backgrounds-gnome

sudo dnf remove -y \
    "*blivet*" \
    "*cangjie*" \
    "*compiz*" \
    "*dragora*" \
    "*emerald*" \
    "*exaile*" \
    "*filezilla*" \
    "*firefox*" \
    "*gnote*" \
    "*gparted*" \
    "*hexchat*" \
    "*libreoffice*" \
    "*lightdm-slick*" \
    "*nano*" \
    "*parole*" \
    "*rxvt*" \
    "*terminal*" \
    "*thunderbird*" \
    "*virtualbox*" \
    "*xfburn*"

sudo dnf install -y caja-open-terminal

echo "export QT_QPA_PLATFORMTHEME=gtk2" | sudo tee /etc/profile.d/qtstyleplugins.sh

git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
chsh -s $(grep /zsh$ /etc/shells | tail -1)

rm -rf .config .cache .mozilla
cd
Settings/apply

#test -f /etc/default/grub.orig || sudo cp /etc/default/grub /etc/default/grub.orig

#cat <<EOF | sudo tee -a /etc/default/grub >> /dev/null
#GRUB_TIMEOUT=0
#GRUB_HIDDEN_TIMEOUT=0
#GRUB_DISABLE_OS_PROBER="true"
#EOF
#sudo sed -i "s/quiet/quiet loglevel=0 vga=current vt.global_cursor_default=0/g" /etc/default/grub
