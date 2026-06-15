#!/usr/bin/env bash
source ../.env

dev=${1:-nvme0n1p2}

MY_UUID=$(blkid -s UUID -o value /dev/$dev)
echo "options root=UUID=$MY_UUID rootflags=subvol=@ rw"
clear && lsblk -f && cat /boot/loader/entries/arch.conf
mkinitcpio -P
