#!/usr/bin/env bash
# ============================================================
# Script 2: Chroot System Configuration + Bootloader + User
# Run INSIDE arch-chroot /mnt
# ============================================================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

[[ $EUID -eq 0 ]] || die "Run as root inside chroot."

echo ""
echo "=================================================="
echo "   Arch Linux Install — Chroot Configuration"
echo "=================================================="
echo ""

# ── Timezone & locale ───────────────────────────────────
info "Setting timezone to Asia/Jakarta..."
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
timedatectl set-ntp true
hwclock --systohc

info "Configuring locale..."
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i 's/^#id_ID.UTF-8 UTF-8/id_ID.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
success "Locale set."

# ── Hostname ────────────────────────────────────────────
read -rp "Hostname [archytech]: " HOSTNAME
HOSTNAME="${HOSTNAME:-archytech}"
echo "$HOSTNAME" > /etc/hostname
success "Hostname set to: $HOSTNAME"

# ── User setup ──────────────────────────────────────────
read -rp "New username: " USERNAME
[[ -n "$USERNAME" ]] || die "Username cannot be empty."

useradd -m -G wheel "$USERNAME"
info "Set password for $USERNAME:"
passwd "$USERNAME"
info "Set root password:"
passwd

# ── Sudoers ─────────────────────────────────────────────
info "Enabling wheel group in sudoers..."
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
success "Wheel group enabled."

# ── Services ────────────────────────────────────────────
info "Enabling services..."
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable ufw
success "Services enabled."

# ── Bootloader ──────────────────────────────────────────
info "Installing systemd-boot..."
bootctl install

cat > /boot/loader/loader.conf << 'LOADER'
default arch
timeout 3
editor no
LOADER

info "Detecting root partition UUID..."
lsblk -f

read -rp "Enter root (Btrfs) partition (e.g. nvme0n1p2): " ROOT_PART
[[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

ROOT_UUID=$(blkid -s UUID -o value /dev/$ROOT_PART)
[[ -n "$ROOT_UUID" ]] || die "Could not get UUID for /dev/$ROOT_PART."

cat > /boot/loader/entries/arch.conf << ENTRY
title     Arch Linux
linux     /vmlinuz-linux
initrd    /amd-ucode.img
initrd    /initramfs-linux.img
options   root=UUID=$ROOT_UUID rootflags=subvol=@ rw
ENTRY

success "Bootloader entry created."
cat /boot/loader/entries/arch.conf

# ── pacman.conf ─────────────────────────────────────────
info "Enabling ParallelDownloads and multilib in pacman.conf..."
nano /etc/pacman.conf
pacman -Syu --noconfirm

# ── mkinitcpio ──────────────────────────────────────────
info "Regenerating initramfs..."
mkinitcpio -P
success "initramfs done."

# ── zram-generator ──────────────────────────────────────────
info "Create zram config"
cat > /etc/systemd/zram-generator.conf << ZRAMCONF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAMCONF
success "zram-gen done."

# ── YAY (AUR helper) ────────────────────────────────────
info "Installing yay as $USERNAME..."
su - "$USERNAME" -c "
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -sir --noconfirm
    rm -rf /tmp/yay
"
success "yay installed."

echo ""
success "Chroot setup complete! Next steps:"
echo "  exit                    # leave chroot"
echo "  umount -R /mnt"
echo "  reboot"
echo ""
warn "After reboot, log in as $USERNAME and run: bash 03-desktop-snapper.sh"
echo ""
