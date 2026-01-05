#!/usr/bin/env bash
set -euo pipefail

# Network setup

echo "Apply hostname..."
cat << EOF > /etc/hostname
koakuma

EOF

echo "Copying network interface configuration..."
install -vm644 config/hosts/koakuma/networkd/* /etc/systemd/network/

echo "Symlink stub-resolv.conf to resolv.conf..."
rm -v /etc/resolv.conf
touch /run/systemd/resolve/stub-resolv.conf
ln -sfv /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "Enable networking services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved

echo "Installing pacman hooks/scripts..."
mkdir -vp /etc/pacman.d/hooks
install -vm644 config/common/pacman/hooks/* /etc/pacman.d/hooks/
mkdir -vp /etc/pacman.d/scripts
install -vm644 config/common/pacman/scripts/* /etc/pacman.d/scripts/
chmod -Rv +x /etc/pacman.d/scripts/*

echo "Installing miscellaneous config drop-ins..."

mkdir -vp /etc/cmdline.d
install -vm644 config/common/cmdline.d/* /etc/cmdline.d/
mkdir -vp /etc/modprobe.d
install -vm644 config/hosts/koakuma/modprobe.d/* /etc/modprobe.d/

echo "Modifying mkinitcpio.conf for ZFS..."
sed -i 's/MODULES=()/MODULES=(zfs)/' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base .*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap sd-vconsole block zfs filesystems)/' /etc/mkinitcpio.conf

echo "Activating zfs-mount-generator..."
mkdir /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/zroot

echo "Enabling ZFS services..."
systemctl enable zfs-zed

zed -F