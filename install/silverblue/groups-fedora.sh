#!/bin/bash

export pkgs_deps=(
    ShellCheck
    fira-code-fonts
    gh
    hub
    kitty
    npm
    neovim
    python3-devel
    python3-pygments
    ripgrep
    shfmt
    zsh
)

export pkgs_tools=(
    android-tools
    nc
    nmap
    rclone
    screen
    rlwrap
    dnf5-plugins
    g++
    p7zip-plugins
    pandoc
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
    gstreamer1-plugin-openh264
    mozilla-openh264
)

export pkgs_virt=(
    swtpm-tools
    edk2-ovmf
    libvirt-daemon-config-network
    libvirt-daemon-kvm
    qemu-kvm
    qemu-user-static
    virt-install
    virt-manager
)

export pkgs_rpm=(
    rpm-build
    rpm-devel
    rpmdevtools
    rpmlint
)

export pkgs_drivers=(
)
