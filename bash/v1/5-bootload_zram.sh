#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../bashenv"

[[ $EUID -eq 0 ]] || die "Run as root inside chroot."

# ── Detection Firmware ──────────────────────────────────
if [[ -d /sys/firmware/efi ]]; then
    BOOT_MODE="UEFI"
else
    BOOT_MODE="BIOS"
fi

case "$BOOT_MODE" in
    UEFI)
        info "Choose bootloader:"
        info "  1) systemd-boot"
        info "  2) GRUB (not recommended for UEFI)"
        info -rp "Choice [1]: " DE_CHOICE
        DE_CHOICE="${DE_CHOICE:-1}"

        if [[ "$DE_CHOICE" == "1" ]]; then
            # ── Bootloader ──────────────────────────────────────────
            info "Installing systemd-boot..."
            bootctl install

            cat > /boot/loader/loader.conf << 'LOADER'
default arch
timeout 3
editor no
LOADER

            info "Detecting root partition UUID..."
            lsblk -f

            read -rp "Enter root (Btrfs) partition (e.g. nvme0n1p2): " ROOT_PART
            [[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

            ROOT_UUID=$(blkid -s UUID -o value /dev/$ROOT_PART)
            [[ -n "$ROOT_UUID" ]] || die "Could not get UUID for /dev/$ROOT_PART."

            cat > /boot/loader/entries/arch.conf << ENTRY
title     Arch Linux
linux     /vmlinuz-linux
initrd    /amd-ucode.img
initrd    /initramfs-linux.img
options   root=UUID=$ROOT_UUID rootflags=subvol=@ rw
ENTRY

            success "Bootloader entry created."
            cat /boot/loader/entries/arch.conf

            # ── mkinitcpio ──────────────────────────────────────────
            info "Regenerating initramfs..."
            mkinitcpio -P
            success "initramfs done."

            # ── zram-generator ──────────────────────────────────────────
            info "Create zram config"
            cat > /etc/systemd/zram-generator.conf << ZRAMCONF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAMCONF
            success "zram-gen done."
        elif [[ "$DE_CHOICE" == "2" ]]; then
            warn "GRUB is not recommended for UEFI systems. Are you sure?"
            read -rp "Type 'yes' to continue: " CONFIRM
            [[ "$CONFIRM" == "yes" ]] || die "Aborted."
            info "Installing GRUB for UEFI..."

            # Required packages

            pacman -S --needed --noconfirm 
            grub 
            efibootmgr 
            os-prober

            # Validate EFI mount

            mountpoint -q /boot || die "/boot is not mounted. Mount EFI partition first."

            # Install GRUB

            grub-install 
            --target=x86_64-efi 
            --efi-directory=/boot 
            --bootloader-id=ArchLinux 
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
        else
            warn "Invalid choice, defaulting to systemd-boot."
            sleep 2
            bash bootloader/systemd-boot.sh
        fi
        ;;
    BIOS)
        info "Installing GRUB for BIOS..."

        pacman -S --needed --noconfirm 
        grub 
        os-prober

        lsblk -d -o NAME,SIZE,TYPE | grep disk
        echo ""
        read -rp "Enter target disk for GRUB install (e.g. sda, nvme0n1): " DISK

        [[ -b "/dev/$DISK" ]] || die "/dev/$DISK not found."

        grub-install 
        --target=i386-pc 
        --recheck 
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
        ;;
esac

# ── Bootloader ──────────────────────────────────────────
info "Installing systemd-boot..."
bootctl install

cat > /boot/loader/loader.conf << 'LOADER'
default arch
timeout 3
editor no
LOADER

info "Detecting root partition UUID..."
lsblk -f

read -rp "Enter root (Btrfs) partition (e.g. nvme0n1p2): " ROOT_PART
[[ -b "/dev/$ROOT_PART" ]] || die "/dev/$ROOT_PART not found."

ROOT_UUID=$(blkid -s UUID -o value /dev/$ROOT_PART)
[[ -n "$ROOT_UUID" ]] || die "Could not get UUID for /dev/$ROOT_PART."

cat > /boot/loader/entries/arch.conf << ENTRY
title     Arch Linux
linux     /vmlinuz-linux
initrd    /amd-ucode.img
initrd    /initramfs-linux.img
options   root=UUID=$ROOT_UUID rootflags=subvol=@ rw
ENTRY

success "Bootloader entry created."
cat /boot/loader/entries/arch.conf

# ── pacman.conf ─────────────────────────────────────────
info "Enabling ParallelDownloads and multilib in pacman.conf..."
nano /etc/pacman.conf
pacman -Syu --noconfirm

# ── mkinitcpio ──────────────────────────────────────────
info "Regenerating initramfs..."
mkinitcpio -P
success "initramfs done."

# ── zram-generator ──────────────────────────────────────────
info "Create zram config"
cat > /etc/systemd/zram-generator.conf << ZRAMCONF
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAMCONF
success "zram-gen done."
