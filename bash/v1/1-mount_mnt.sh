#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

echo ""
read -rp "EFI partition (e.g. nvme0n1p1): " EFI_PART
[[ -b "/dev/$EFI_PART" ]]  || die "/dev/$EFI_PART not found."
read -rp "Root (Btrfs) partition (e.g. nvme0n1p2): " ROOT_PART
[[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

# ── Mount subvolumes ────────────────────────────────────
info "Mounting @ subvolume..."
mount -o compress=zstd,subvol=@ /dev/$ROOT_PART /mnt

info "Creating mount directories..."
mkdir -p /mnt/{boot,home,var/log,var/lib/docker,.snapshots}

info "Mounting subvolumes..."
sleep 1
mount -o compress=zstd,subvol=@home         /dev/$ROOT_PART /mnt/home
mount -o compress=zstd,subvol=@varlog       /dev/$ROOT_PART /mnt/var/log
mount -o compress=zstd,subvol=@docker       /dev/$ROOT_PART /mnt/var/lib/docker
mount -o compress=zstd,subvol=@snapshots    /dev/$ROOT_PART /mnt/.snapshots

info "Creating mount directories...@snapshots_home"
sleep 1
mkdir "/mnt/home/.snapshots"
mount -o compress=zstd,subvol=@snapshots_home /dev/$ROOT_PART /mnt/home/.snapshots

mount /dev/$EFI_PART /mnt/boot

success "All partitions mounted."
