#!/bin/bash

export pkgs_deps=(
    fira-code-fonts
    kitty
    npm
    neovim
    ripgrep
    zsh
)

export pkgs_deps_bluefin=(
    fira-code-fonts
    kitty
    neovim
    npm
    quilt
    remmina
)

export pkgs_tools=(
    android-tools
    dnf5-plugins
    gitk
    nc
    nmap
    p7zip-plugins
    quilt
)

export pkgs_cockpit=(
    cockpit
    cockpit-composer
    cockpit-file-sharing
    cockpit-kdump
    cockpit-machines
    cockpit-navigator
    cockpit-networkmanager
    cockpit-ostree
    cockpit-packagekit
    cockpit-podman
    cockpit-selinux
    cockpit-session-recording
    cockpit-sosreport
    cockpit-storaged
)

export pkgs_apps=(
    gimp
    inkscape
    gnome-text-editor
)

export pkgs_base=(
)

export pkgs_virt=(
    cockpit
    cockpit-machines
    guestfs-tools
    qemu-kvm-core
    virt-install
)

export pkgs_rpm=(
    createrepo_c
    rpm-build
    rpm-devel
    rpmdevtools
    rpmlint
)

export pkgs_drivers=(
)

export pkgs_docker=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

export pkgs_misc=(
    waydroid
)
