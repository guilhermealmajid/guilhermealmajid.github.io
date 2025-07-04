#!/bin/bash
# Debian Sway Installer (UEFI) from Arch Live - All-in-One
# Run: sudo -i

# CONFIG (Edit these!)
DISK="/dev/nvme0n1"       # NVMe (or /dev/sda)
HOSTNAME="debian-sway"
USERNAME="guilherme"           # Your username
USER_PASS="admin"   # Change this!
COUNTRY="BR"             # BR, US, etc.
TIMEZONE="America/Sao_Paulo"

# Minimal package lists
BASE_PKGS="linux-image-amd64 firmware-linux grub-efi-amd64 sudo vim"
SWAY_PKGS="sway swaybg swayidle swaylock cool-retro-term waybar wofi grim slurp wl-clipboard"
NETWORK_PKGS="network-manager iw rfkill wpa_supplicant" 

# ====== INSTALLATION ======
# Partition disk (UEFI)
wipefs -a $DISK
parted -s $DISK mklabel gpt
parted -s $DISK mkpart primary fat32 1MiB 513MiB
parted -s $DISK set 1 esp on
parted -s $DISK mkpart primary ext4 513MiB 100%

# Format
mkfs.fat -F32 "${DISK}p1"
mkfs.ext4 -F "${DISK}p2"

# Mount
mount "${DISK}p2" /mnt
mkdir -p /mnt/boot/efi
mount "${DISK}p1" /mnt/boot/efi

# Install base
pacman -Sy --noconfirm debootstrap
debootstrap bookworm /mnt http://deb.debian.org/debian

# Prepare chroot
mount --bind /dev /mnt/dev
mount --bind /proc /mnt/proc
mount --bind /sys /mnt/sys

# Chroot script
cat > /mnt/install.sh <<EOF
#!/bin/bash

# Basic config
echo "$HOSTNAME" > /etc/hostname
echo "127.0.1.1 $HOSTNAME" >> /etc/hosts
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime

# APT sources with backports
cat > /etc/apt/sources.list <<SRC_EOF
deb http://deb.debian.org/debian bookworm main contrib non-free
deb http://deb.debian.org/debian bookworm-updates main contrib non-free
deb http://security.debian.org bookworm-security main contrib non-free
deb http://deb.debian.org/debian bookworm-backports main contrib non-free
SRC_EOF

# Install packages
apt update && apt install -y \\
    $BASE_PKGS $SWAY_PKGS $NETWORK_PKGS

# Brazilian keyboard (ABNT2)
cat > /etc/default/keyboard <<KBD_EOF
XKBMODEL="abnt2"
XKBLAYOUT="br"
XKBVARIANT=""
KBD_EOF
setupcon --force

# Create user
useradd -m -G sudo,video -s /bin/bash $USERNAME
echo "$USERNAME:$USER_PASS" | chpasswd

# Services
systemctl enable NetworkManager

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=Debian
update-grub

# Cleanup
rm /install.sh
EOF

# Run install
chmod +x /mnt/install.sh
chroot /mnt /bin/bash /install.sh

# Finish
umount -R /mnt
echo "=== INSTALL COMPLETE ==="
echo "1. Reboot"
echo "2. Login and run 'sway'"
echo "3. WiFi? Use 'nmtui'"
