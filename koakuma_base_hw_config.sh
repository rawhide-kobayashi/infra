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

pacstrap -KP /mnt base linux-cachyos-bore-lto linux-cachyos-bore-lto-zfs linux-firmware zfs-utils vim systemd-resolvconf

echo "Copy fstab..."
install -vm644 config/koakuma/fstab /mnt/etc/fstab

echo "Symlink stub-resolv.conf to resolv.conf..."
rm -v /etc/resolv.conf
touch /run/systemd/resolve/stub-resolv.conf
ln -sfv ../run/systemd/resolve/stub-resolv.conf /mnt/etc/resolv.conf

echo "Chroot into OS..."
arch-chroot /mnt
cd ~

echo "Mount EFI..."
mkdir /efi
mkdir /efi2
mount -a

echo "Setting hostname..."
echo "Apply hostname..."
cat << EOF > /etc/hostname
koakuma

EOF

echo "Setting timezone and locale..."
ln -sf /usr/share/zoneinfo/US/Central /etc/localtime
hwclock --systohc
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
cat << EOF > /etc/locale.conf
LANG=en_US.UTF-8

EOF

echo "Copying network interface configuration..."
install -vm644 config/hosts/koakuma/networkd/* /etc/systemd/network/

echo "Enable networking services..."
systemctl enable systemd-networkd
systemctl enable systemd-resolved

echo "Installing pacman hooks/scripts..."
mkdir -vp /etc/pacman.d/hooks
install -vm644 config/common/pacman/hooks/* /etc/pacman.d/hooks/
mkdir -vp /etc/pacman.d/scripts
install -vm744 config/common/pacman/scripts/* /etc/pacman.d/scripts/

echo "Installing miscellaneous config drop-ins..."

mkdir -vp /etc/cmdline.d
install -vm644 config/common/cmdline.d/* /etc/cmdline.d/
mkdir -vp /etc/modprobe.d
install -vm644 config/hosts/koakuma/modprobe.d/* /etc/modprobe.d/

echo "Modifying mkinitcpio.conf for ZFS..."
sed -i 's/MODULES=()/MODULES=(zfs)/' /etc/mkinitcpio.conf
sed -i 's/HOOKS=(base .*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block zfs filesystems)/' /etc/mkinitcpio.conf

echo "Running script to correct mkinitcpio presets and regenerating efi images..."
/etc/pacman.d/scripts/overwrite-uki
mkinitcpio -P

echo "Activating zfs-mount-generator..."
mkdir /etc/zfs/zfs-list.cache
touch /etc/zfs/zfs-list.cache/zroot

echo "Enabling ZFS services..."
systemctl enable zfs-zed

echo "Starting Zed for zfs-mount-generator... Exit script manually and remember to reinstall your kernel to trigger an EFI rebuild."
zed -F