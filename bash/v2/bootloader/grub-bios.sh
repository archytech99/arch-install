#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../../.env"

info "Installing GRUB for BIOS..."

pacman -S --needed --noconfirm \
grub \
os-prober

lsblk -d -o NAME,SIZE,TYPE | grep disk
echo ""
read -rp "Enter target disk for GRUB install (e.g. sda, nvme0n1): " DISK

[[ -b "/dev/$DISK" ]] || die "/dev/$DISK not found."

grub-install \
--target=i386-pc \
--recheck \
/dev/$DISK

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

success "GRUB BIOS installation complete."
