#!/bin/bash
(
    cd /etc/yum.repos.d/ && curl -LO https://copr.fedorainfracloud.org/coprs/nforro/i3-gaps/repo/fedora-rawhide/nforro-i3-gaps-fedora-rawhide.repo
    echo "export QT_QPA_PLATFORMTHEME=gtk2" | sudo tee /etc/profile.d/qtstyleplugins.sh
    rpm-ostree reset
    rpm-ostree update
    rpm-ostree override remove fedora-coreos-pinger
    rpm-ostree install \
        ImageMagick \
        NetworkManager-bluetooth \
        NetworkManager-l2tp-gnome \
        NetworkManager-openvpn-gnome \
        NetworkManager-wifi \
        NetworkManager-wwan \
        adapta-gtk-theme \
        alsa-plugins-pulseaudio \
        arm-image-installer \
        atril-caja \
        atril-thumbnailer \
        blueberry \
        caja-actions \
        caja-image-converter \
        caja-open-terminal \
        caja-sendto \
        caja-wallpaper \
        caja-xattr-tags \
        engrampa \
        eom \
        firefox \
        glx-utils \
        gnome-epub-thumbnailer \
        gvfs-fuse \
        gvfs-mtp \
        i3-gaps \
        lightdm-gtk-greeter-settings \
        lm_sensors \
        mate-applets \
        mate-desktop \
        mate-icon-theme \
        mate-media \
        mate-menus \
        mate-menus-preferences-category-menu \
        mate-power-manager \
        mate-screensaver \
        mate-sensors-applet \
        mate-session-manager \
        mate-system-monitor \
        mate-themes \
        mate-user-admin \
        mate-utils \
        mesa-dri-drivers \
        mesa-vulkan-drivers \
        network-manager-applet \
        nm-connection-editor \
        pavucontrol \
        picom \
        qt5-qtstyleplugins \
        synapse \
        system-config-language \
        system-config-printer \
        system-config-printer-applet \
        xorg-x11-drv-ati \
        xorg-x11-drv-fbdev \
        xorg-x11-drv-intel \
        xorg-x11-drv-libinput \
        xorg-x11-drv-nouveau \
        xorg-x11-drv-openchrome \
        xorg-x11-drv-qxl \
        xorg-x11-drv-vesa \
        xorg-x11-server-Xorg \
        xorg-x11-utils \
        xorg-x11-xauth \
        zeitgeist \
        zsh

    # swap file instructions:
    # sudo fallocate -l 8G /var/swapfile
    # sudo chmod 600 /var/swapfile
    # sudo mkswap /var/swapfile
    # sudo swapon /var/swapfile
    # sudoedit /etc/fstab
    # /var/swapfile swap swap defaults 0 0
    # sudo filefrag -v /var/swapfile
    # echo 20189 | sudo tee /sys/power/resume_offset
    # sudo rpm-ostree kargs --append=resume=/dev/sda4 --append=resume_offset=20189
)
