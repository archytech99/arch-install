#!/usr/bin/env bash
# ============================================================
# Script 1: Partition, Format, Mount, Pacstrap
# Run from Arch Linux Live USB
# ============================================================
source ../.env

clear
echo ""
echo "=================================================="
echo "   Arch Linux Install — Partition & Pacstrap"
echo "=================================================="
echo ""

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
lsblk /dev/$DISK

# ── Pacstrap ────────────────────────────────────────────
info "Running pacstrap (this may take a while)..."
pacstrap -K /mnt \
    base linux linux-firmware linux-headers systemd amd-ucode \
    sudo nano btop git curl wget openssh bash-completion \
    networkmanager ufw snapper zram-generator base-devel \
    reflector rsync fastfetch net-tools man-db man-pages

info "Generating fstab..."
echo "genfstab -U /mnt >> /mnt/etc/fstab"
success "fstab generated."
echo "cat /mnt/etc/fstab"

echo ""
success "Pacstrap complete! Next step:"
echo "  cp 02-chroot-setup.sh /root/02-chroot-setup.sh"
echo "  cp 03-desktop-snapper.sh /root/03-desktop-snapper.sh"
echo "  arch-chroot /mnt"
echo "  bash /root/02-chroot-setup.sh"
echo ""
