#!/usr/bin/env bash
set -euo pipefail

echo "Copy fstab..."
install -vm644 config/hosts/patchouli/fstab /etc/fstab
mount -a

echo "Copying network interface configuration..."
rm -rfv /etc/systemd/network/*
install -vm644 config/hosts/patchouli/networkd/* /etc/systemd/network/

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
install -vm644 config/hosts/patchouli/modprobe.d/* /etc/modprobe.d/

echo "Modifying mkinitcpio.conf for ZFS..."
sed -i 's/MODULES=()/MODULES=(zfs)/' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base .*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block zfs filesystems)/' /etc/mkinitcpio.conf

echo "Copy initcpio hooks..."
rm -rfv /etc/initcpio/install/*
install -vm644 config/common/initcpio/install/* /etc/initcpio/install/

echo "Copy kanidm configuration & restart daemons..."
rm -rfv /etc/kanidm/*
install -vm644 config/common/kanidm/* /etc/kanidm/
install -vm644 config/common/pam.d/* /etc/pam.d/
install -vm644 config/common/nsswitch.conf /etc/nsswitch.conf
systemctl restart kanidm-unixd.service

echo "Install sudoers configuration..."
rm -rfv /etc/sudoers.d/*
install -vm440 config/common/sudoers.d/* /etc/sudoers.d/

echo "Install samba configuration..."
install -vm644 config/hosts/patchouli/samba/smb.conf /etc/samba/smb.conf
systemctl restart smb

echo "Install zrepl configuration..."
rm -rfv /etc/zrepl/jobs.d/*
install -vm644 config/hosts/patchouli/zrepl/jobs.d/* /etc/zrepl/jobs.d/
install -vm644 config/hosts/patchouli/zrepl/zrepl.yml /etc/zrepl/zrepl.yml
systemctl restart zrepl