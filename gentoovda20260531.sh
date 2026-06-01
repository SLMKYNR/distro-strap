#!/bin/bash
# run script after root like below
# sudo -s

# git clone https://github.com/SLMKYNR/distro-strap.git
# cd distro-strap
# cat gentoovda20260531.sh | head -20
# chmod +x gentoovda20260531.sh
# ./gentoovda20260531.sh

# cat gentoovda20260531.sh | tail -25



set -e

# Clean mounts
# umount -R /mnt
# umount -l /dev/vda*


# Partition disk
echo "********************** Partition ======================"
parted -s /dev/vda mklabel gpt
parted -s /dev/vda mkpart ESP fat32 1MiB 1025MiB
parted -s /dev/vda set 1 esp on
parted -s /dev/vda mkpart primary ext4 1025MiB 100%

echo "********************** Partition Done Mkfs======================"
# Make filesystems
mkfs.fat -F 32 /dev/vda1
mkfs.ext4 -F /dev/vda2

# Mount root
echo "********************** Mkfs Done Mounting ======================"
mkdir -p /mnt/gentoo
mount /dev/vda2 /mnt/gentoo

# Mount EFI partition
mkdir -p /mnt/gentoo/boot/efi
mount /dev/vda1 /mnt/gentoo/boot/efi

echo "********************** Mounting Done Timesync ======================"

# Time sync
ln -sf /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
date
#chronyd -q



# Stage3
cd /mnt/gentoo
#cp /home/gentoo/Downloads/stage3-amd64-openrc-20260531T160106Z.tar.xz /mnt/gentoo/
wget https://distfiles.gentoo.org/releases/amd64/autobuilds/20260531T160106Z/stage3-amd64-openrc-20260531T160106Z.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo

# Portage config
sed -i '/^FFLAGS=/a MAKEOPTS="-j20"' /mnt/gentoo/etc/portage/make.conf
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/

# Mount necessary filesystems for chroot
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run


echo "********************** Entering Chroot **********************"

chroot /mnt/gentoo /bin/bash <<'EOF'
echo "============== Inside chroot **********************"
source /etc/profile

echo "********************** starting emerge-webrsync **********************"
emerge-webrsync
echo "********************** webrsync done emerge-sync **********************"
ls /mnt/
emerge --sync --quiet
ls /mnt/
echo "********************** done emerge --sync --quiet **********************"

#eselect profile set 44
#eselect profile show

PROFILE_NUM=$(eselect profile list | grep -F "default/linux/amd64/23.0 (stable)" | awk '{print $1}' | tr -d '[]')
eselect profile set "$PROFILE_NUM"

# Verify
eselect profile show
sed -i '/^MAKEOPTS=/a USE="-systemd -kde -gnome -bluetooth"' /etc/portage/make.conf


echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf
emerge --ask --verbose --update --deep --changed-use @world


ln -sf ../usr/share/zoneinfo/Europe/Istanbul /etc/localtime
sed -i 's/^# en_US/en_US/' /etc/locale.gen
echo "********************** GENERATING LOCALE **********************"
locale-gen

eselect locale set en_US.UTF-8

echo "********************** BEF ENV **********************"
env-update 
echo "********************** BEF SOURCE **********************"
source /etc/profile
echo "********************** BEF LANG **********************"
echo $LANG

echo "********************** AFTER LANG **********************"
emerge sys-kernel/linux-firmware
emerge sys-firmware/sof-firmware

echo "sys-kernel/installkernel grub dracut" >> /etc/portage/package.use/installkernel
emerge sys-kernel/installkernel
emerge sys-kernel/gentoo-kernel-bin

echo "********************** FSTAB ==============================="
echo '/dev/vda1       /boot/efi       vfat    defaults        0 2' >> /etc/fstab
echo '/dev/vda2       /               ext4    noatime         0 1' >> /etc/fstab

echo gentoo > /etc/hostname
sed -i 's/^hostname=.*/hostname="gentoo"/' /etc/conf.d/hostname

emerge net-misc/dhcpcd
rc-update add dhcpcd default 


echo 'root:root' | chpasswd
echo "********************** TOOLS **********************"
emerge app-shells/bash-completion

echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
emerge sys-boot/grub

#mount -t efivarfs efivarfs /sys/firmware/efi/efivars
grub-install --efi-directory=/boot/efi --target=x86_64-efi
grub-mkconfig -o /boot/grub/grub.cfg

#cp /usr/lib/modules/6.18.32-p2-gentoo-dist/vmlinuz /boot/vmlinuz-6.18.32-p2-gentoo-dist
#grub-mkconfig -o /boot/grub/grub.cfg

echo "********************** FINALIZING **********************"
useradd -m -G wheel sk
echo 'sk:sk' | chpasswd

emerge sudo

#emerge --getbinpkg xorg-server
emerge dwm
emerge st

EOF
# Out of Chroot
ls /mnt/


#cd /
#umount -R /mnt
#reboot
