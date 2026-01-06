#!/usr/bin/env bash
set -euo pipefail

echo "Copying network interface configuration..."
rm -rfv /etc/systemd/network/*
install -vm644 config/hosts/koakuma/networkd/* /etc/systemd/network/

echo "Restarting networking services..."
systemctl restart systemd-networkd.service
systemctl restart systemd-resolved.service

echo "Installing pacman hooks/scripts..."
rm -rfv /etc/pacman.d/hooks/*
install -vm644 config/common/pacman/hooks/* /etc/pacman.d/hooks/
rm -rfv /etc/pacman.d/scripts/*
install -vm744 config/common/pacman/scripts/* /etc/pacman.d/scripts/

echo "Installing miscellaneous config drop-ins..."
rm -rfv /etc/cmdline.d/*
install -vm644 config/common/cmdline.d/* /etc/cmdline.d/
rm -rfv /etc/modprobe.d/*
install -vm644 config/hosts/koakuma/modprobe.d/* /etc/modprobe.d/

echo "Modifying mkinitcpio.conf for ZFS..."
sed -i 's/MODULES=()/MODULES=(zfs)/' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base .*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block zfs filesystems)/' /etc/mkinitcpio.conf
