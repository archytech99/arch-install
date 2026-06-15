#!/usr/bin/env bash
# ============================================================
# Script 3: Desktop Environment, Drivers & Snapper Setup
# Run after first boot, as your normal user (sudo access)
# ============================================================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

[[ $EUID -ne 0 ]] || die "Run as normal user (with sudo), not root."

echo ""
echo "=================================================="
echo "   Arch Linux Install — Desktop & Snapper"
echo "=================================================="
echo ""

# ── Desktop environment ─────────────────────────────────
echo "Choose desktop environment:"
echo "  1) KDE Plasma"
echo "  2) Hyprland"
echo "  3) Hyprland via ML4W"
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
        steam btrfs-assistant libreoffice
    success "GPU drivers and apps installed."

elif [[ "$DE_CHOICE" == "2" ]]; then
    info "Installing Hyprland..."
    sudo pacman -Syu --noconfirm

    info "Installing core packages..."
    sudo pacman -S --needed --noconfirm \
        sudo \
        git \
        base-devel \
        unzip \
        zip \
        wget \
        curl \
        reflector \
        rsync \
        man-db \
        man-pages \
        networkmanager \
        bluez \
        bluez-utils \
        openssh \
        fastfetch

    info "Enabling essential services..."
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth

    info "Installing audio stack..."
    sudo pacman -S --needed --noconfirm \
        pipewire \
        wireplumber \
        pipewire-pulse \
        pipewire-alsa \
        pipewire-jack \
        pavucontrol

    info "Installing graphics stack..."
    sudo pacman -S --needed --noconfirm \
        mesa \
        vulkan-radeon \
        vulkan-intel \
        vulkan-tools \
        egl-wayland \
        libva-utils \
        brightnessctl

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
        cliphist \
        grim \
        slurp \
        waybar \
        rofi-wayland \
        dunst \
        kitty \
        nautilus \
        nwg-look \
        qt6ct \
        swww \
        playerctl \
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
        dolphin \
        polkit-kde-agent

    info "Installing display manager..."
    sudo pacman -S --needed --noconfirm sddm
    sudo systemctl enable sddm

    info "Creating default hyprland config..."
    mkdir -p $HOME/.config/hypr
    cat > $HOME/.config/hypr/hyprland.lua << 'EOF'
-- See: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

local terminal    = "kitty"
local fileManager = "dolphin"
local menu        = "rofi -show drun"
local cmd         = "rofi -show run"

hl.on("hyprland.start", function () 
    hl.exec_cmd(terminal)
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("waybar & hyprpaper")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 14,
        border_size = 2,
        col = {
            active_border   = { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding       = 10,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },
        blur = {
            enabled   = true,
            size      = 3,
            passes    = 1,
            vibrancy  = 0.1696,
        },
    },
    animations = {
        enabled = true,
    },
})

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })
hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

hl.config({
    master = {
        new_status = "master",
    },
})

hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,
    },
})

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = {
            natural_scroll = false,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

local mainMod = "SUPER"
local secondMod = "SUPER + SHIFT"
local thirdMod = "SUPER + CTRL"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(thirdMod .. " + L", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(thirdMod .. " + SPACE", hl.dsp.exec_cmd(cmd))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(secondMod .. " + " .. key,     hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
EOF

    info ""

    success "Installation complete!"
elif [[ "$DE_CHOICE" == "3" ]]; then
    info "Launching ML4W Hyprland installer..."
    sudo pacman -Syu --noconfirm

    info "Installing base dependencies"
    sudo pacman -S --needed --noconfirm \
        git \
        base-devel \
        unzip \
        zip \
        wget \
        curl \
        reflector \
        rsync \
        man-db \
        man-pages \
        networkmanager \
        bluez \
        bluez-utils \
        openssh \
        fastfetch

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
        cliphist \
        hypridle \
        hyprlock \
        nwg-look \
        qt6ct \
        grim \
        slurp \
        playerctl \
        ttf-font-awesome

    info "Enabling essential services..."
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth

    if ! command -v yay &> /dev/null; then
        warning "yay not found. Installing yay..."

        tmp_dir=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

        cd "$tmp_dir/yay"
        makepkg -si --noconfirm
    fi

    info "Installing AUR packages"
    yay -S --needed --noconfirm \
        quickshell \
        oh-my-posh-bin \
        python-pywal \
        aw-watcher-wallpaper \
        bibata-cursor-theme \
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
sudo snapper -c root create --description "Fresh Arch Install"
sudo snapper -c home create --description "Fresh Arch Install"
success "Snapshots created."

echo ""
sudo snapper -c root ls
sudo snapper -c home ls

echo ""
success "All done! Your Arch Linux system is ready."
warn "Tip: always run paired snapshots before major changes:"
echo "  sudo snapper -c root create --description 'pre-update'"
echo "  sudo snapper -c home create --description 'pre-update'"
echo ""
read -rp "Reboot system now ? [y/N] " reboot
if [[ "$reboot" =~ ^[Yy]$ ]]; then
    sudo reboot now
fi
