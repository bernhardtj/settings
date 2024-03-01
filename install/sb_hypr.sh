#!/bin/bash
#
#

# f40 config
: '
Deployments:
● fedora:fedora/40/x86_64/sericea
                  Version: 40.20240229.n.0 (2024-02-29T08:22:41Z)
               BaseCommit: 23548ad856f9d579f126510f301c36a2f90a693954b4e988a610b19a4e56d992
             GPGSignature: Valid signature by 115DF9AEF857853EE8445D0A0727707EA15B79CC
      RemovedBasePackages: foot 1.16.1-3.fc40 grimshot 1.9~rc2-1.fc40 rofi-wayland 1.7.5+wayland2-3.fc40 sddm 0.20.0-11.fc40 sddm-wayland-sway sway-config-fedora 0.4.1-1.fc40
                           sway 1.9-1.fc40 sway-systemd 0.4.0-3.fc40
           LocalOverrides: fedora-logos 38.1.0-5.fc40 -> 39.1.0-2.fc39
          LayeredPackages: dconf-editor fira-code-fonts gh hub hyprland lightdm-gtk-greeter-settings mate-applets mate-icon-theme mate-panel neovim npm python3-pygments ShellCheck shfmt
                           synapse xorg-x11-server-Xorg zsh
            LocalPackages: adapta-gtk-theme-3.95.0.11-3.fc31.noarch
'
# todo f40
#
# [ ] dunst

pkgs=(
    aylurs-gtk-shell
    #eww-wayland-git
    #hyprland
    hyprland-autoname-workspaces
    hyprland-contrib
    hyprland-git
    #hyprland-legacyrenderer
    #hyprland-nvidia
    #hyprland-nvidia-git
    hyprland-plugins
    hyprpaper
    hyprpicker
    hyprshot
    kitty
    #libdisplay-info
    #libinput
    #libliftoff
    #pixman
    sdbus-cpp
    #waybar-git
    #wayland
    #wayland-protocols
    xdg-desktop-portal-hyprland
    #xorg-x11-server-Xwayland
)

extras=(
    #azote
    brightnessctl
    git
    gvfs-smb
    #i3exit
    socat
    polkit-gnome
    neovim
    wlr-randr
    wob

    i3
    synapse
    picom

    http://mirror.math.princeton.edu/pub/fedora-archive/fedora/linux/releases/31/Everything/x86_64/os/Packages/a/adapta-gtk-theme-3.95.0.11-3.fc31.noarch.rpm
)

sudo wget "https://copr.fedorainfracloud.org/coprs/solopasha/hyprland/repo/fedora-$(rpm -E %fedora)/solopasha-hyprland-fedora-$(rpm -E %fedora).repo" \
    -O "/etc/yum.repos.d/solopasha-hyprland-fedora-$(rpm -E %fedora).repo"

mate_pkgs=(
    NetworkManager-adsl
    NetworkManager-iodine-gnome
    NetworkManager-ovs
    NetworkManager-ppp
    NetworkManager-ssh-gnome
    NetworkManager-strongswan-gnome
    NetworkManager-team
    abrt-desktop
    abrt-java-connector
    atril
    atril-caja
    atril-thumbnailer
    blivet-gui
    caja
    caja-actions
    caja-image-converter
    caja-open-terminal
    caja-sendto
    caja-wallpaper
    caja-xattr-tags
    dconf-editor
    dnfdragora-updater
    engrampa
    eom
    f38-backgrounds-extras-base
    f38-backgrounds-extras-mate
    f38-backgrounds-mate
    filezilla
    firewall-config
    gnome-disk-utility
    gnome-epub-thumbnailer
    gnome-logs
    gnome-themes-extra
    gnote
    gparted
    gtk2-engines
    gucharmap
    gvfs-afc
    gvfs-afp
    gvfs-archive
    gvfs-fuse
    gvfs-gphoto2
    gvfs-mtp
    gvfs-nfs
    gvfs-smb
    hexchat
    initial-setup-gui
    libmatekbd
    libmatemixer
    libmateweather
    lightdm
    lm_sensors
    marco
    mate-applets
    mate-backgrounds
    mate-calc
    mate-control-center
    mate-desktop
    mate-dictionary
    mate-disk-usage-analyzer
    mate-icon-theme
    mate-media
    mate-menus
    mate-menus-preferences-category-menu
    mate-notification-daemon
    mate-panel
    mate-polkit
    mate-power-manager
    mate-screensaver
    mate-screenshot
    mate-search-tool
    mate-session-manager
    mate-settings-daemon
    mate-system-log
    mate-system-monitor
    mate-terminal
    mate-themes
    mate-user-admin
    mate-user-guide
    mozo
    orca
    p7zip
    p7zip-plugins
    parole
    pluma
    seahorse
    seahorse-caja
    setroubleshoot
    simple-scan
    slick-greeter-mate
    system-config-language
    system-config-printer-applet
    thunderbird
    transmission-gtk
    usermode-gtk
    xdg-user-dirs-gtk
    xfburn
    yelp

    caja-beesu
    caja-share
    firewall-applet
    mate-menu
    mate-sensors-applet
    mate-utils
    multimedia-menus
    pidgin
    pluma-plugins
    python3-caja
    tigervnc
)

rpm-ostree reset
rpm-ostree rebase fedora:fedora/38/x86_64/sericea
rpm-ostree override replace --experimental xorg-x11-server-Xwayland --from repo='copr:copr.fedorainfracloud.org:solopasha:hyprland'
#rpm-ostree override remove firefox-langpacks firefox xdg-desktop-portal-wlr
rpm-ostree update "${pkgs[@]/#/--install=}" "${extras[@]/#/--install=}"
rpm-ostree install "${mate_pkgs[@]}" --idempotent --allow-inactive
