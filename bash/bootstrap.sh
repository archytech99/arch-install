#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/bashenv"

info "You can run this bootstrap script to execute all"
info "installation steps in one go or run each script"
info "manually in 'arch-install/bash/v1/' or"
info "'arch-install/bash/v2/' folders for more control."
sleep 3
info "Choose install method:"
info "  1) (minimal, manual setup)"
info "  2) (guided, automated setup)"
info "  or (E)xit"
read -rp "Choice [2]: " DE_CHOICE
DE_CHOICE="${DE_CHOICE:-2}"
[[ "$DE_CHOICE" =~ ^[Ee]$ ]] && return 0

if [[ "$DE_CHOICE" == "1" ]]; then
    info "Just 'cd' into v1/ and run each script in order number-wise"
    # bash v1/0-btrfs_mnt.sh
    # bash v1/1-mount_mnt.sh
    # bash v1/2-pacstrap_mnt.sh
    # bash v1/3-lctime-hostname.sh
    # bash v1/4-user_sudoers.sh
    # bash v1/5-bootload_zram.sh
    # bash v1/6-desktop_environment.sh
    # bash v1/7-setup_snapshots.sh
elif [[ "$DE_CHOICE" == "2" ]]; then
    bash v2/01-partition-pacstrap.sh
    #bash v2/02-chroot-setup.sh
    #bash v2/03-desktop-snapper.sh
    echo ""
    info "Bootstrap completed."
else
    die "Invalid choice. Exiting."
    exit 1
fi
