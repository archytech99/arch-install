#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

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

# ── YAY (AUR helper) ────────────────────────────────────
info "Installing yay as $USERNAME..."
su - "$USERNAME" -c "
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -sir --noconfirm
    rm -rf /tmp/yay
"
success "yay installed."

# ── Services ────────────────────────────────────────────
info "Enabling services..."
systemctl enable NetworkManager
systemctl enable sshd
systemctl enable ufw
success "Services enabled."
