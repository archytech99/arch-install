#!/usr/bin/env bash
source ../.env

# ── Desktop environment ─────────────────────────────────
echo "Choose desktop environment:"
echo "  1) KDE Plasma"
echo "  2) Hyprland via ML4W"
read -rp "Choice [1]: " DE_CHOICE
DE_CHOICE="${DE_CHOICE:-1}"

if [[ "$DE_CHOICE" == "1" ]]; then
    info "Installing KDE Plasma..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm plasma-meta dolphin konsole kate sddm xorg
    sudo systemctl enable sddm
    success "KDE Plasma installed."

    info "Installing audio stack..."
    sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber
    success "PipeWire installed."

    info "Installing GPU drivers and apps..."
    sudo pacman -S --noconfirm \
        mesa vulkan-radeon lib32-vulkan-radeon \
        steam btrfs-assistant libreoffice unzip p7zip
    success "GPU drivers and apps installed."

elif [[ "$DE_CHOICE" == "2" ]]; then
    info "Launching ML4W Hyprland installer..."
    info "Updating system"
    sudo pacman -Syu --noconfirm

    info "Installing base dependencies"
    sudo pacman -S --needed --noconfirm \
        git \
        base-devel \
        curl \
        wget \
        unzip

    info "Installing yay (if not installed)"
    if ! command -v yay >/dev/null 2>&1; then
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        cd /tmp/yay
        makepkg -si --noconfirm
        cd -
    fi

    info "Installing official repository packages"
    sudo pacman -S --needed --noconfirm \
        kitty \
        neovim \
        firefox \
        nautilus \
        yazi \
        dolphin \
        waybar \
        rofi-wayland \
        pywal \
        cliphist \
        hypridle \
        hyprlock \
        nwg-look \
        qt6ct \
        grim \
        slurp \
        ttf-font-awesome \
        bibata-cursor-theme

    info "Installing AUR packages"
    yay -S --needed --noconfirm \
        quickshell \
        oh-my-posh-bin \
        aw-watcher-wallpaper \
        grimblast-git \
        nwg-dock-hyprland \
        kora-icon-theme

    info "Optional browsers"
    read -rp "Install Chromium? [y/N] " install_chromium
    if [[ "$install_chromium" =~ ^[Yy]$ ]]; then
        sudo pacman -S --needed --noconfirm chromium
    fi

    read -rp "Install Brave? [y/N] " install_brave
    if [[ "$install_brave" =~ ^[Yy]$ ]]; then
        yay -S --needed --noconfirm brave-bin
    fi
    info "Installing ML4W Hyprland"
    bash <(curl -s https://ml4w.com/os/stable)

    success "Installation completed"
    read -rp "Reboot system now ? [y/N] " reboot
    if [[ "$reboot" =~ ^[Yy]$ ]]; then
        sudo reboot now
    fi
else
    die "Invalid choice."
fi
