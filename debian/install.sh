#!/bin/bash

set -e

# === CONFIGURAÇÕES ===
DISK="/dev/sdX"           # Altere para /dev/sda, /dev/vda etc.
EFI="${DISK}1"
ROOT="${DISK}2"
MNT="/mnt/debian"
DIST="bookworm"
HOST="debian-basic"
USER="usuario"
PASS="senha123"           # Senha root e usuário comum

# === PARTICIONAMENTO GPT ===
wipefs -a "$DISK"
parted -s "$DISK" mklabel gpt
parted -s "$DISK" mkpart ESP fat32 1MiB 513MiB
parted -s "$DISK" set 1 esp on
parted -s "$DISK" mkpart ROOT ext4 513MiB 100%

# === FORMATAÇÃO ===
mkfs.fat -F32 "$EFI"
mkfs.ext4 -F "$ROOT"

# === MONTAGEM ===
mkdir -p "$MNT"
mount "$ROOT" "$MNT"
mkdir -p "$MNT/boot/efi"
mount "$EFI" "$MNT/boot/efi"

# === INSTALAÇÃO DO SISTEMA BASE ===
debootstrap "$DIST" "$MNT" http://deb.debian.org/debian

# === MONTAGENS DO SISTEMA ===
for dir in dev proc sys; do mount --bind /$dir "$MNT/$dir"; done

# === PREPARAÇÃO: UUIDs para fstab ===
UUID_ROOT=$(blkid -s UUID -o value "$ROOT")
UUID_EFI=$(blkid -s UUID -o value "$EFI")

cat <<EOF > "$MNT/etc/fstab"
UUID=$UUID_ROOT / ext4 defaults 0 1
UUID=$UUID_EFI  /boot/efi vfat umask=0077 0 1
EOF

# === CHROOT E CONFIGURAÇÃO ===
chroot "$MNT" /bin/bash <<EOF
set -e

echo "$HOST" > /etc/hostname
echo "127.0.1.1 $HOST" >> /etc/hosts

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

apt update
apt install -y linux-image-amd64 grub-efi-amd64 sudo network-manager systemd-timesyncd expect

systemctl enable NetworkManager
systemctl enable systemd-timesyncd

# === SENHA ROOT COM PASSWD (expect) ===
expect <<EOL
spawn passwd root
expect "New password:"
send "$PASS\r"
expect "Retype new password:"
send "$PASS\r"
expect eof
EOL

# === USUÁRIO PADRÃO COM PASSWD (expect) ===
useradd -m -s /bin/bash "$USER"
usermod -aG sudo "$USER"

expect <<EOL
spawn passwd "$USER"
expect "New password:"
send "$PASS\r"
expect "Retype new password:"
send "$PASS\r"
expect eof
EOL

# === INSTALAR E CONFIGURAR GRUB UEFI ===
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=debian
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "✅ Debian básico instalado com EXT4, GRUB, usuário e fstab atualizado."
