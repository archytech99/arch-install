#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../bashenv"

info "Installing GRUB for UEFI..."

# Required packages

pacman -S --needed --noconfirm \
grub \
efibootmgr \
os-prober

# Validate EFI mount

mountpoint -q /boot || die "/boot is not mounted. Mount EFI partition first."

# Install GRUB

grub-install \
--target=x86_64-efi \
--efi-directory=/boot \
--bootloader-id=ArchLinux \
--recheck

# Optional: enable os-prober

if grep -q "^#GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    sed -i 's/^#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
elif ! grep -q "^GRUB_DISABLE_OS_PROBER=false" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
fi

if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
    sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="rootflags=subvol=@ rw"|' /etc/default/grub
else
    echo 'GRUB_CMDLINE_LINUX_DEFAULT="rootflags=subvol=@ rw"' >> /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg

success "GRUB UEFI installation complete."
