#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

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

# ── zram-generator ──────────────────────────────────────────
info "Create zram config"
cat > /etc/systemd/zram-generator.conf << ZRAMCONF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAMCONF
success "zram-gen done."

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
