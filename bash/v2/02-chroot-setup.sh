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

# ── Detection Firmware ──────────────────────────────────
if [[ -d /sys/firmware/efi ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

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

# ── Sudoers ─────────────────────────────────────────────
info "Enabling wheel group in sudoers..."
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
success "Wheel group enabled."

# ── User setup ──────────────────────────────────────────
info "Create new user? (Recommended for daily use instead of root)"
read -rp "Answer (Y)es/(N)o: " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
    read -rp "New username: " USERNAME
    [[ -n "$USERNAME" ]] || die "Username cannot be empty."

    useradd -m -G wheel "$USERNAME"
    info "Set password for $USERNAME:"
    passwd "$USERNAME"

    # ── YAY (AUR helper) ────────────────────────────────────
    info "Installing yay as $USERNAME..."
    su - "$USERNAME" -c "
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -sir --noconfirm
        rm -rf /tmp/yay
    "
    success "yay installed."
fi
info "Set root password:"
passwd

# ── Services ────────────────────────────────────────────
info "Enabling services..."
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable ufw
success "Services enabled."

# ── pacman.conf ─────────────────────────────────────────
info "Enabling Parallel Downloads and multilib in pacman.conf..."
sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sed -i 's|^#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|' /etc/pacman.conf
#nano /etc/pacman.conf
pacman -Syu --noconfirm

case "$BOOT_MODE" in
    UEFI)
        info "Choose bootloader:"
        info "  1) systemd-boot"
        info "  2) GRUB (not recommended for UEFI)"
        read -rp "Choice [1]: " DE_CHOICE
        DE_CHOICE="${DE_CHOICE:-1}"

        if [[ "$DE_CHOICE" == "1" ]]; then
            bash $SCRIPT_DIR/bootloader/systemd-boot.sh
        elif [[ "$DE_CHOICE" == "2" ]]; then
            warn "GRUB is not recommended for UEFI systems. Are you sure?"
            read -rp "Type 'yes' to continue: " CONFIRM
            [[ "$CONFIRM" == "yes" ]] || die "Aborted."
            bash $SCRIPT_DIR/bootloader/grub-efi.sh
        else
            warn "Invalid choice, defaulting to systemd-boot."
            sleep 2
            bash $SCRIPT_DIR/bootloader/systemd-boot.sh
        fi
        ;;
    BIOS)
        bash $SCRIPT_DIR/bootloader/grub-bios.sh
        ;;
esac

info ""
success "Chroot setup complete! Next steps:"
info "  exit                    # leave chroot"
info "  umount -R /mnt"
info "  reboot and run: bash 03-desktop-snapper.sh"
info ""
