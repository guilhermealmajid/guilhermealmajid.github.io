#!/bin/sh

set -e

DISK="/dev/sdX"  # <--- Altere para o disco correto
EFI="${DISK}1"
ROOT="${DISK}2"
MNT="/mnt/debian"
HOST="debian-btrfs"
DIST="bookworm"
USER="usuario"
PASS="senha123"

# 1. Particionamento
wipefs -a "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart ROOT btrfs 513MiB 100%

# 2. Formatação
mkfs.fat -F32 "$EFI"
mkfs.btrfs -f "$ROOT"

# 3. Montagem inicial e subvolumes
mkdir -p "$MNT"
mount "$ROOT" "$MNT"

for SUB in @ @home @var @snapshots; do
  btrfs subvolume create "$MNT/$SUB"
done

umount "$MNT"

# 4. Montagem real
mount -o subvol=@,compress=zstd,noatime "$ROOT" "$MNT"
for DIR in home var .snapshots; do
  mkdir -p "$MNT/$DIR"
  mount -o subvol=@$DIR,compress=zstd,noatime "$ROOT" "$MNT/$DIR"
done

mkdir -p "$MNT/boot/efi"
mount "$EFI" "$MNT/boot/efi"

# 5. Instalação mínima
debootstrap "$DIST" "$MNT" http://deb.debian.org/debian

# 6. Bind mounts
mount --bind /dev "$MNT/dev"
mount --bind /proc "$MNT/proc"
mount --bind /sys "$MNT/sys"

# 7. Configuração dentro do chroot
chroot "$MNT" /bin/bash <<EOF
echo "$HOST" > /etc/hostname
echo "127.0.1.1 $HOST" >> /etc/hosts

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

apt update
apt install -y linux-image-amd64 btrfs-progs grub-efi-amd64 network-manager sudo \
               systemd-timesyncd zram-tools

systemctl enable NetworkManager
systemctl enable systemd-timesyncd
systemctl enable zramswap

# Root
echo "root:$PASS" | chpasswd

# Usuário comum com sudo
useradd -m -s /bin/bash "$USER"
echo "$USER:$PASS" | chpasswd
usermod -aG sudo "$USER"

# GRUB
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "✅ Instalação concluída com ZRAM como swap. Pode reiniciar o sistema."
