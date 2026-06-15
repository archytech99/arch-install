#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

# ── Snapper dance — root ────────────────────────────────
info "Running Snapper setup for / (root)..."
sudo umount /.snapshots
sudo rmdir /.snapshots
sudo snapper -c root create-config /
sudo btrfs subvolume delete /.snapshots
sudo mkdir /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
success "Snapper root config done."

# ── Snapper dance — home ────────────────────────────────
info "Running Snapper setup for /home..."
sudo umount /home/.snapshots
sudo rmdir /home/.snapshots
sudo snapper -c home create-config /home
sudo btrfs subvolume delete /home/.snapshots
sudo mkdir /home/.snapshots
sudo mount -a
sudo chmod 750 /home/.snapshots
success "Snapper home config done."

# ── Initial paired snapshots ────────────────────────────
info "Creating initial paired snapshots..."
sudo snapper -c root create --description "Fresh Arch Install"
sudo snapper -c home create --description "Fresh Arch Install"
success "Snapshots created."

echo ""
sudo snapper -c root ls
sudo snapper -c home ls

echo ""
success "All done! Your Arch Linux system is ready."
warn "Tip: always run paired snapshots before major changes:"
echo "  sudo snapper -c root create --description 'pre-update'"
echo "  sudo snapper -c home create --description 'pre-update'"
echo ""
