lsblk
sudo -i
fdisk --version
fdisk /dev/sda
m
g	create a new empty GPT partition table
p	print the partition table
n	add a new partition
+1M
t	change a partition type
4	BIOS BOOT
p	print the partition table

n
+1G
t	change a partition type
enter 	Linux File System
p	print the partition table

n
"enter"
"enter"
t
"enter" Linux File System
p	print the partition table

w	write table to disk and exit

mkfs.ext4 /dev/sda2
mkfs.fat -F 32 /dev/sda1
mount /dev/sda2 /mnt
mkdir -p /mnt/boot/efi
sudo mount /dev/sda1 /mnt/boot/efi

wget 'https://deb.debian.org/debian/pool/main/d/debootstrap/debootstrap_1.0.143_all.deb'
dpkg -i debootstrap_*.*.*_all.deb

debootstrap --arch amd64 stable /mnt https://deb.debian.org/debian

mount --make-rslave --rbind /proc /mnt/proc
mount --make-rslave --rbind /sys /mnt/sys
mount --make-rslave --rbind /dev /mnt/dev
mount --make-rslave --rbind /run /mnt/run

chroot /mnt /bin/bash

lsblk -f /dev/sda >> /etc/fstab
nano /etc/fstab

apt install ca-certificates lsb-release

CODENAME=$(lsb_release --codename --short)
cat > /etc/apt/sources.list << HEREDOC
deb https://deb.debian.org/debian/ $CODENAME main contrib non-free
deb-src https://deb.debian.org/debian/ $CODENAME main contrib non-free

deb https://security.debian.org/debian-security $CODENAME-security main contrib non-free
deb-src https://security.debian.org/debian-security $CODENAME-security main contrib non-free

deb https://deb.debian.org/debian/ $CODENAME-updates main contrib non-free
deb-src https://deb.debian.org/debian/ $CODENAME-updates main contrib non-free
HEREDOC

nano /etc/apt/sources.list

apt update

dpkg-reconfigure tzdata

apt install locales
dpkg-reconfigure locales

apt search linux-image
apt install linux-image-amd64

apt install firmware-linux

echo "debian" > /etc/hostname

cat > /etc/hosts << HEREDOC
127.0.0.1 localhost
127.0.1.1 $(cat /etc/hostname)

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
HEREDOC

apt install network-manager

apt install grub2
passwd

useradd sk -m -s /bin/bash
passwd sk

apt install sudo
usermod -aG sudo sk

apt install efibootmgr efivar grub-efi grub-efi-amd64-signed

grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
update-grub

update-initramfs -u

exit

umount -R /mnt

reboot


tasksel --list-tasks




