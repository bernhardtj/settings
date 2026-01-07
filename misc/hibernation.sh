#!/bin/bash
# to enable hibernation on >f40
#
# already handled by rpm-ostree image initramfs:
# - dracut "resume" module which supersedes the resume= karg
# - in the case of nvidia drivers, the params to save the driver memory should be already set
# - due to issues with KMS: Pick 2: {nvidia, wayland, hibernation}
#
# NOTE: after running this, handle-lid-switch needs to be changed!
# $  systemd-analyze cat-config systemd/logind.conf
# also HibernateDelaySec= in systemd/sleep.conf needs to be set for laptops
#

set -xe

SWAPSIZE=33G # at least the size of your ram or it won't work
SWAPFILE=/var/swap/swapfile

sudo btrfs subvolume create /var/swap
sudo btrfs filesystem mkswapfile --size $SWAPSIZE --uuid clear $SWAPFILE
# using the btrfs commands instead of mkswap already disables COW

echo $SWAPFILE none swap defaults 0 0 | sudo tee --append /etc/fstab
sudo swapon --all --verbose

sudo semanage fcontext --add --type swapfile_t $SWAPFILE
sudo restorecon -RF /var/swap

systemd-analyze cat-config systemd/logind.conf
systemd-analyze cat-config systemd/sleep.conf
