#!/usr/bin/env bash
set -euo pipefail

echo "Creating root zpool..."
zpool create -f -o ashift=12 -o autotrim=on -O aclinherit=passthrough -O aclmode=passthrough -O acltype=nfsv4 \
-O canmount=off -O compression=zstd -O devices=off -O direct=disabled -O dnodesize=auto -O mountpoint=none \
-O normalization=formD -R /mnt zroot mirror \
/dev/disk/by-id/ata-LITEON_CV3-CE512-11_SATA_512GB_TW001D79LOH006BS00ZF-part2 \
/dev/disk/by-id/ata-LITEON_CV3-CE512-11_SATA_512GB_TW001D79LOH006BS00ZZ-part2


zfs create -o mountpoint=none zroot/data
zfs create -o mountpoint=none zroot/roots
zfs create -o mountpoint=/ -o canmount=noauto zroot/roots/default
zfs create -o mountpoint=none zroot/common
zfs create -o mountpoint=/var -o canmount=off zroot/var
zfs create zroot/var/log
zfs create zroot/var/lib
zfs create -o recordsize=1M -o mountpoint=/var/cache/pacman/pkg zroot/var/pkgcache

echo "Export/import and mount zroot datasets..."
zpool export zroot
zpool import -d /dev/disk/by-id -R /mnt zroot -N
zfs mount zroot/roots/default
zfs mount -a

echo "Bootstrapping OS..."
sed -i '/#NoExtract/i\
NoExtract = /usr/share/libalpm/hooks/zz-sbctl.hook' /etc/pacman.conf
sed -i '/\[cachyos\]/i\
[cachyos-v3]\
Include = /etc/pacman.d/cachyos-v3-mirrorlist\
\
[cachyos-core-v3]\
Include = /etc/pacman.d/cachyos-v3-mirrorlist\
\
[cachyos-extra-v3]\
Include = /etc/pacman.d/cachyos-v3-mirrorlist\
' /etc/pacman.conf

pacstrap -P /mnt base linux-firmware-intel vim systemd-resolvconf openssh mkinitcpio cachyos-keyring \
cachyos-mirrorlist cachyos-v3-mirrorlist cachyos-rate-mirrors sbctl intel-ucode

echo "Import cachyos keys and init keyring..."
pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
pacman-key --lsign-key F3B607488DB35A47
pacman-key --init
pacman-key --populate

echo "Copy fstab..."
install -vm644 config/hosts/koakuma/fstab /mnt/etc/fstab

echo "Symlink stub-resolv.conf to resolv.conf..."
rm -v /mnt/etc/resolv.conf
ln -sfv ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

echo "Mount EFI..."
mkdir /mnt/efi
mkdir /mnt/efi2
arch-chroot /mnt mount -a
rm -rfv /mnt/efi/EFI/*
mkdir -pv /mnt/efi/EFI/Linux
mkdir -pv /mnt/efi/EFI/Linux_bak
mkdir -pv /mnt/efi/EFI/Linux_checkpoint

echo "Install refind..."
refind-install --usedefault /dev/sda1

echo "Apply hostname..."
cat << EOF > /mnt/etc/hostname
koakuma

EOF

echo "Setting timezone and locale..."
arch-chroot /mnt ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
arch-chroot /mnt locale-gen
cat << EOF > /mnt/etc/locale.conf
LANG=en_US.UTF-8

EOF

echo "Copying network interface configuration..."
install -vm644 config/hosts/koakuma/networkd/* /mnt/etc/systemd/network/

echo "Enable networking services..."
arch-chroot /mnt systemctl enable systemd-networkd.service
arch-chroot /mnt systemctl enable systemd-resolved.service
arch-chroot /mnt systemctl enable sshd.service
arch-chroot /mnt systemctl enable cachyos-rate-mirrors.timer

echo "Installing pacman hooks/scripts..."
mkdir -vp /mnt/etc/pacman.d/hooks
install -vm644 config/common/pacman/hooks/* /mnt/etc/pacman.d/hooks/
mkdir -vp /mnt/etc/pacman.d/scripts
install -vm744 config/common/pacman/scripts/* /mnt/etc/pacman.d/scripts/

echo "Installing miscellaneous config drop-ins..."

mkdir -vp /mnt/etc/cmdline.d
install -vm644 config/common/cmdline.d/* /mnt/etc/cmdline.d/
mkdir -vp /mnt/etc/modprobe.d
install -vm644 config/hosts/koakuma/modprobe.d/* /mnt/etc/modprobe.d/

echo "Modifying mkinitcpio.conf for ZFS..."
sed -i 's/MODULES=()/MODULES=(zfs)/' /mnt/etc/mkinitcpio.conf
sed -i 's/HOOKS=(base .*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block zfs filesystems)/' /mnt/etc/mkinitcpio.conf

echo "Creating bespoke secure boot keys and enrolling..."
arch-chroot /mnt sbctl create-keys
arch-chroot /mnt sbctl enroll-keys -m

echo "Installing kernel/ZFS..."
arch-chroot /mnt pacman -Sy --noconfirm linux-cachyos-bore-lto linux-cachyos-bore-lto-zfs zfs-utils

echo "Activating zfs-mount-generator..."
mkdir /mnt/etc/zfs/zfs-list.cache
touch /mnt/etc/zfs/zfs-list.cache/zroot

echo "Enabling ZFS services..."
arch-chroot /mnt systemctl enable zfs.target
arch-chroot /mnt systemctl enable zfs-zed.service

echo "Starting Zed to bootstrap zfs-mount-generator... Exit script manually."
arch-chroot /mnt zed -F