#!/usr/bin/env bash
# ============================================================
# Script 3: Desktop Environment, Drivers & Snapper Setup
# Run after first boot, as your normal user (sudo access)
# ============================================================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../bashenv"

[[ $EUID -ne 0 ]] || die "Run as normal user (with sudo), not root."

echo ""
info "=================================================="
info "   Arch Linux Install — Desktop & Snapper"
info "=================================================="
echo ""

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
#sudo snapper -c root create --description "Fresh Arch Install"
sudo snapper -c root create -t pre -d "Fresh Arch Install"
#sudo snapper -c home create --description "Fresh Arch Install"
sudo snapper -c home create -t pre -d "Fresh Arch Install"
success "Snapshots created."

info ""
sudo snapper -c root ls
sudo snapper -c home ls

# ── YAY (AUR helper) ────────────────────────────────────
if ! command -v yay &> /dev/null; then
    warn "yay not found. Installing yay..."

    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
fi

# ── Time synchronization ────────────────────────────────
sudo timedatectl set-ntp true

# ── Desktop environment ─────────────────────────────────
info "Choose desktop environment:"
info "  1) KDE Plasma"
info "  2) Hyprland"
info "  3) Hyprland via ML4W"
read -rp "Choice [1]: " DE_CHOICE
DE_CHOICE="${DE_CHOICE:-1}"

if [[ "$DE_CHOICE" == "1" ]]; then
    info "Installing KDE Plasma..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --noconfirm \
        plasma-meta dolphin konsole kate sddm xorg \
        libreoffice steam btrfs-assistant
    sudo systemctl enable sddm
    success "KDE Plasma installed."

    info "Installing audio stack..."
    sudo pacman -S --noconfirm pipewire pipewire-pulse pipewire-alsa wireplumber
    success "PipeWire installed."

    info "Installing graphics stack..."
    install_gpu_driver

elif [[ "$DE_CHOICE" == "2" ]]; then
    info "Installing Hyprland..."
    sudo pacman -Syu --noconfirm

    info "Installing core packages..."
    sudo pacman -S --needed --noconfirm \
        unzip \
        zip \
        bluez \
        bluez-utils \
        btrfs-assistant \
        fastfetch

    info "Enabling essential services..."
    sudo systemctl enable bluetooth

    info "Installing audio stack..."
    sudo pacman -S --needed --noconfirm \
        pipewire \
        wireplumber \
        pipewire-pulse \
        pipewire-alsa \
        pipewire-jack \
        playerctl \
        pavucontrol

    info "Installing graphics stack..."
    install_gpu_driver

    info "Installing Hyprland ecosystem..."
    sudo pacman -S --needed --noconfirm \
        hyprland \
        xdg-desktop-portal \
        xdg-desktop-portal-hyprland \
        hyprlock \
        hypridle \
        hyprpaper \
        hyprpicker \
        hyprlauncher \
        xdg-utils \
        wl-clipboard \
        chromium \
        blueman \
        grim \
        slurp \
        waybar \
        rofi-wayland \
        dunst \
        kitty \
        dolphin \
        nwg-look \
        qt6ct \
        swww \
        pamixer \
        network-manager-applet \
        ttf-font-awesome \
        noto-fonts \
        noto-fonts-cjk \
        noto-fonts-emoji \
        otf-font-awesome

    info "Installing minimal KDE (no kde-applications)..."
    sudo pacman -S --needed --noconfirm \
        plasma-desktop \
        nautilus \
        polkit-kde-agent

    info "Installing display manager..."
    sudo pacman -S --needed --noconfirm sddm
    sudo systemctl enable sddm

    info "Installing AUR packages"
    yay -S --needed --noconfirm \
        clipman \
        python-pywal \
        aw-watcher-wallpaper \
        bibata-cursor-theme \
        ttf-jetbrains-mono-nerd \
        kora-icon-theme \
        inotify-tools

    info "Creating default setup Hyprland & Waybar"
    read -rp "Continue [Y]es/[N]o : " CFG_CHOICE
    if [[ "$CFG_CHOICE" =~ ^[Yy]$ ]]; then
        create_config_setup_minimal
    fi

    success "Installation complete!"
elif [[ "$DE_CHOICE" == "3" ]]; then
    info "Launching ML4W Hyprland installer..."
    sudo pacman -Syu --noconfirm

    info "Installing base dependencies"
    sudo pacman -S --needed --noconfirm \
        unzip \
        zip \
        bluez \
        bluez-utils \
        fastfetch

    info "Installing official repository packages"
    sudo pacman -S --needed --noconfirm \
        kitty \
        neovim \
        nautilus \
        yazi \
        dolphin \
        waybar \
        rofi-wayland \
        cliphist \
        hypridle \
        hyprlock \
        nwg-look \
        qt6ct \
        grim \
        slurp \
        playerctl \
        ttf-font-awesome \
        noto-fonts \
        noto-fonts-cjk \
        noto-fonts-emoji \
        otf-font-awesome

    info "Enabling essential services..."
    sudo systemctl enable bluetooth

    info "Installing audio stack..."
    sudo pacman -S --needed --noconfirm \
        pipewire \
        wireplumber \
        pipewire-pulse \
        pipewire-alsa \
        pipewire-jack \
        playerctl \
        pavucontrol

    info "Installing graphics stack..."
    install_gpu_driver

    info "Installing AUR packages"
    yay -S --needed --noconfirm \
        quickshell \
        oh-my-posh-bin \
        python-pywal \
        aw-watcher-wallpaper \
        bibata-cursor-theme \
        grimblast-git \
        nwg-dock-hyprland \
        ttf-jetbrains-mono-nerd \
        kora-icon-theme \
        inotify-tools

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

    info "Installing display manager..."
    sudo pacman -S --needed --noconfirm \
        sddm \
        polkit-kde-agent \
        xdg-desktop-portal \
        xdg-desktop-portal-hyprland
    sudo systemctl enable sddm

    success "Installation completed"
else
    die "Invalid choice."
fi

info "Creating default sddm config..."
sudo tee /etc/sddm.conf > /dev/null << 'EOF'
[Autologin]
Relogin=false
Session=
User=

[General]
DisplayServer=x11
GreeterEnvironment=
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot
InputMethod=qtvirtualkeyboard
Namespaces=
Numlock=none

[Theme]
Current=breeze
CursorSize=breeze
CursorTheme=breeze
DisableAvatarsThreshold=7
EnableAvatars=true
FacesDir=/usr/share/sddm/faces
Font=
ThemeDir=/usr/share/sddm/themes

[Users]
DefaultPath=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin
DefaultShell=/bin/bash
HideShells=/bin/false,/usr/sbin/nologin,/sbin/nologin
HideUsers=
MaximumUid=60513
MinimumUid=1000
RememberLastSession=true
RememberLastUser=true
ReuseSession=true

[Wayland]
CompositorCommand=weston --shell=kiosk
EnableHiDPI=true
SessionCommand=/usr/share/sddm/scripts/wayland-session
SessionDir=/usr/local/share/wayland-sessions,/usr/share/wayland-sessions
SessionLogFile=.local/share/sddm/wayland-session.log

[X11]
DisplayCommand=/usr/share/sddm/scripts/Xsetup
DisplayStopCommand=/usr/share/sddm/scripts/Xstop
EnableHiDPI=true
ServerArguments=-nolisten tcp
ServerPath=/usr/bin/X
SessionCommand=/usr/share/sddm/scripts/Xsession
SessionDir=/usr/local/share/xsessions,/usr/share/xsessions
SessionLogFile=.local/share/sddm/xorg-session.log
XephyrPath=/usr/bin/Xephyr
EOF
sleep 1

sudo snapper -c root create -t post --pre-number 1 -d "Fresh Desktop Environment"
sudo snapper -c home create -t post --pre-number 1 -d "Fresh Desktop Environment"

echo ""
success "All done! Your Arch Linux system is ready."
echo ""
read -rp "Reboot system now ? [y/N] " reboot
if [[ "$reboot" =~ ^[Yy]$ ]]; then
    sudo reboot now
fi
