#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../bashenv"

# ── Pacstrap ────────────────────────────────────────────
info "Running pacstrap (this may take a while)..."
pacstrap -K /mnt \
    base linux linux-firmware linux-headers systemd amd-ucode \
    sudo nano btop git curl wget openssh bash-completion eva \
    networkmanager ufw snapper zram-generator base-devel \
    reflector rsync fastfetch net-tools man-db man-pages \
    grub efibootmgr os-prober

info "Generating fstab..."
info "genfstab -U /mnt >> /mnt/etc/fstab"
success "fstab generated."
info "cat /mnt/etc/fstab"
