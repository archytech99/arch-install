#!/usr/bin/env bash
# ============================================================
# Script 1: Partition, Format, Mount, Pacstrap
# Run from Arch Linux Live USB
# ============================================================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

clear
info ""
info "=================================================="
info "   Arch Linux Install — Partition & Pacstrap"
info "=================================================="
info ""

# ── Detection Firmware ──────────────────────────────────
if [[ -d /sys/firmware/efi ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

info "Detected boot mode: $BOOT_MODE"

# ── Disk selection ──────────────────────────────────────
lsblk -d -o NAME,SIZE,TYPE | grep disk
info ""
warn "note: Make sure to create partition /boot for"
warn "UEFI mode, or BIOS boot partition for GPT+GRUB in BIOS mode."
warn "BIOS+GPT requires bios_grub partition (1–5 MiB)"
echo ""
read -rp "Enter disk (e.g. nvme0n1 or sda): " DISK
[[ -b "/dev/$DISK" ]] || die "Disk /dev/$DISK not found."

info ""
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
info ""
lsblk /dev/$DISK
info ""
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    read -rp "Boot partition (e.g. nvme0n1p1): " BOOT_PART
    [[ -b "/dev/$BOOT_PART" ]] || die "/dev/$BOOT_PART not found."
fi

read -rp "Root partition (e.g. nvme0n1p2): " ROOT_PART
[[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

# ── Format ──────────────────────────────────────────────
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    info "Formatting EFI partition..."
    mkfs.fat -F32 /dev/$BOOT_PART
elif [[ "$BOOT_MODE" == "BIOS" ]]; then
    info "BIOS mode detected, skipping partition formatting."
    sleep 2
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
if [[ "$BOOT_MODE" == "UEFI" ]]; then
    mount /dev/$BOOT_PART /mnt/boot
fi

success "All partitions mounted."
lsblk /dev/$DISK

# ── Pacstrap ────────────────────────────────────────────
info "Running pacstrap (this may take a while)..."
pacstrap -K /mnt \
    base linux linux-firmware linux-headers systemd amd-ucode \
    sudo nano btop git curl wget openssh bash-completion \
    networkmanager ufw snapper zram-generator base-devel \
    reflector rsync fastfetch net-tools man-db man-pages

info "Generating fstab..."
sleep 1
genfstab -U /mnt >> /mnt/etc/fstab
success "fstab generated."
cat /mnt/etc/fstab

info ""
success "Pacstrap complete! Next step:"
info "  arch-chroot /mnt"
info "  bash -x /root/02-chroot-setup.sh"
sleep 2
info ""
