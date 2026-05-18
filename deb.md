# ============================
# Debootstrap Debian EFI Install
# ============================

# ----------------------------
# Disk Partitioning
# ----------------------------


fdisk /dev/sda
g

n
+1G
t	c
1

n
"enter"
"enter"

w	write table to disk and exit

# ----------------------------
# Format partitions
# ----------------------------
mkfs.ext4 -F /dev/sda2
mkfs.fat -F 32 /dev/sda1

# ----------------------------
# Mount partitions
# ----------------------------
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
mount /dev/sda1 /mnt/boot/efi


# ----------------------------
# Bootstrap Debian amd64 stable without variant
# ----------------------------
debootstrap --arch amd64 stable /mnt https://deb.debian.org/debian

# ----------------------------
# Bind essential filesystems for chroot
# ----------------------------
mount --make-rslave --rbind /proc /mnt/proc
mount --make-rslave --rbind /sys /mnt/sys
mount --make-rslave --rbind /dev /mnt/dev
mount --make-rslave --rbind /run /mnt/run

# ----------------------------
# Generate fstab AFTER debootstrap
# ----------------------------
echo "UUID=$(blkid -s UUID -o value /dev/sda2) / ext4 errors=remount-ro 0 1" > /mnt/etc/fstab
echo "UUID=$(blkid -s UUID -o value /dev/sda1) /boot/efi vfat umask=0077 0 1" >> /mnt/etc/fstab

# ----------------------------
# Chroot and run setup commands
# ----------------------------

# ----------------------------
# TIMEZONE (Europe/Istanbul)
# ----------------------------
ln -fs /usr/share/zoneinfo/Europe/Istanbul /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# ----------------------------
# Update sources.list
# ----------------------------

echo "deb http://deb.debian.org/debian/ stable main contrib non-free non-free-firmware" > /etc/apt/sources.list
echo "deb-src http://deb.debian.org/debian/ stable main contrib non-free non-free-firmware" >> /etc/apt/sources.list

echo "deb http://security.debian.org/debian-security stable-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list
echo "deb-src http://security.debian.org/debian-security stable-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list

echo "deb http://deb.debian.org/debian/ stable-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list
echo "deb-src http://deb.debian.org/debian/ stable-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list

echo "deb http://deb.debian.org/debian/ stable-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list
echo "deb-src http://deb.debian.org/debian/ stable-backports main contrib non-free non-free-firmware" >> /etc/apt/sources.list

apt update

# ----------------------------
# Locales
# ----------------------------
apt install -y locales

sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen 
update-locale LANG=en_US.UTF-8
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# ----------------------------
# Kernel
# ----------------------------
apt install -y linux-image-amd64

# ----------------------------
# Firmware
# ----------------------------
apt install -y firmware-linux

# ----------------------------
# Hostname
# ----------------------------
echo 'debian' > /etc/hostname
sed -i '1a 127.0.1.1\tdebian' /etc/hosts

# ----------------------------
# Network 
# ----------------------------
apt install -y network-manager

# ----------------------------
# sudo
# ----------------------------
apt install -y sudo

# ----------------------------
# Users
# ----------------------------
echo 'root:root' | chpasswd

useradd -m -s /bin/bash sk
echo 'sk:sk' | chpasswd
usermod -aG sudo sk

# ----------------------------
# EFI boot
# ----------------------------
apt install -y efibootmgr efivar grub-efi grub-efi-amd64-signed
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB /dev/sda
update-grub
update-initramfs -u

# ----------------------------
# Desktop Env
# ----------------------------
# apt install -y lxde 

# ----------------------------
# Explicit exit from chroot
# ----------------------------
exit

# ----------------------------
# Exit chroot, unmount, reboot
# ----------------------------
cd /
umount -R /mnt

reboot





