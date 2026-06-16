#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

# ── Timezone & locale ───────────────────────────────────
info "Setting timezone to Asia/Jakarta..."
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
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
