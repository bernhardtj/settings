#!/bin/bash

cd /etc/yum.repos.d && copr-enable nforro/i3-gaps
rpm-ostree install i3-gaps picom qt5-qtstyleplugins synapse \
    http://mirror.math.princeton.edu/pub/fedora-archive/fedora/linux/releases/31/Everything/x86_64/os/Packages/a/adapta-gtk-theme-3.95.0.11-3.fc31.noarch.rpm
