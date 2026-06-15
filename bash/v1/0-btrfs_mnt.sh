#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

# ── Disk selection ──────────────────────────────────────
lsblk -d -o NAME,SIZE,TYPE | grep disk
echo ""
read -rp "Enter disk (e.g. nvme0n1 or sda): " DISK
[[ -b "/dev/$DISK" ]] || die "Disk /dev/$DISK not found."

echo ""
warn "All data on /dev/$DISK will be destroyed!"
read -rp "Type 'yes' to continue: " CONFIRM
[[ "$CONFIRM" == "yes" ]] || die "Aborted."

# ── Partition ───────────────────────────────────────────
info "Opening cfdisk for /dev/$DISK — create EFI (512M, type EFI System) and root partitions."
sleep 2
cfdisk /dev/$DISK

# ── Identify partitions ─────────────────────────────────
echo ""
lsblk /dev/$DISK
echo ""
read -rp "EFI partition (e.g. nvme0n1p1): " EFI_PART
read -rp "Root (Btrfs) partition (e.g. nvme0n1p2): " ROOT_PART

[[ -b "/dev/$EFI_PART" ]]  || die "/dev/$EFI_PART not found."
[[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

# ── Format ──────────────────────────────────────────────
info "Formatting EFI partition as FAT32..."
mkfs.fat -F32 /dev/$EFI_PART

info "Formatting root partition as Btrfs..."
mkfs.btrfs -f /dev/$ROOT_PART

# ── Create Btrfs subvolumes ─────────────────────────────
info "Mounting root to create subvolumes..."
mount /dev/$ROOT_PART /mnt

for subvol in @ @home @varlog @docker @snapshots @snapshots_home; do
    btrfs subvolume create /mnt/$subvol
    success "Created subvol: $subvol"
done

umount /mnt
