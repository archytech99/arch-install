#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../bashenv"

# ── Detection Firmware ──────────────────────────────────
if [[ -d /sys/firmware/efi ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

info "Detected boot mode: $BOOT_MODE"

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
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    info "Create EFI (512M FAT32) + Root partition"
else
    info "Create Root partition only (or BIOS boot partition if GPT+GRUB)"
fi
sleep 2
cfdisk /dev/$DISK

# ── Identify partitions ─────────────────────────────────
echo ""
lsblk /dev/$DISK
echo ""
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    read -rp "EFI partition (e.g. nvme0n1p1): " EFI_PART
    [[ -b "/dev/$EFI_PART" ]] || die "/dev/$EFI_PART not found."
fi

read -rp "Root partition (e.g. nvme0n1p2): " ROOT_PART
[[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

# ── Format ──────────────────────────────────────────────
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    info "Formatting EFI partition..."
    mkfs.fat -F32 /dev/$EFI_PART
fi

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
