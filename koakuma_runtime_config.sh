#!/usr/bin/env bash
set -euo pipefail

echo "Copying network interface configuration..."
install -vm644 config/hosts/koakuma/networkd/* /etc/systemd/network/

echo "Restarting networking services..."
systemctl restart systemd-networkd.service
systemctl restart systemd-resolved.service
systemctl restart sshd.service

echo "Installing pacman hooks/scripts..."
install -vm644 config/common/pacman/hooks/* /mnt/etc/pacman.d/hooks/
install -vm744 config/common/pacman/scripts/* /mnt/etc/pacman.d/scripts/

echo "Installing miscellaneous config drop-ins..."

install -vm644 config/common/cmdline.d/* /mnt/etc/cmdline.d/
mkdir -vp /mnt/etc/modprobe.d
install -vm644 config/hosts/koakuma/modprobe.d/* /mnt/etc/modprobe.d/

echo "Modifying mkinitcpio.conf for ZFS..."
sed -i 's/MODULES=()/MODULES=(zfs)/' /mnt/etc/mkinitcpio.conf
sed -i 's/HOOKS=(base .*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block zfs filesystems)/' /mnt/etc/mkinitcpio.conf
