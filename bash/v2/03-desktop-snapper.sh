#!/usr/bin/env bash
# ============================================================
# Script 3: Desktop Environment, Drivers & Snapper Setup
# Run after first boot, as your normal user (sudo access)
# ============================================================
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/../.env"

[[ $EUID -ne 0 ]] || die "Run as normal user (with sudo), not root."

info ""
info "=================================================="
info "   Arch Linux Install — Desktop & Snapper"
info "=================================================="
info ""

# ── YAY (AUR helper) ────────────────────────────────────
if ! command -v yay &> /dev/null; then
    warning "yay not found. Installing yay..."

    tmp_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"

    cd "$tmp_dir/yay"
    makepkg -si --noconfirm
fi

# ── Time synchronization ────────────────────────────────
timedatectl set-ntp true

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
    info "Choose GPU vendor:"
    info "  1) AMD"
    info "  2) NVIDIA"
    info "  3) Intel"
    read -rp "Choice [1]: " GPU_CHOICE
    GPU_CHOICE="${GPU_CHOICE:-1}"
    if [[ "$GPU_CHOICE" == "1" ]]; then
        info "Installing AMD GPU stack..."
        sudo pacman -S --needed --noconfirm \
            mesa \
            vulkan-radeon \
            vulkan-intel \
            vulkan-tools \
            lib32-vulkan-radeon \
            lib32-mesa \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "AMD stack installed."
    elif [[ "$GPU_CHOICE" == "2" ]]; then
        info "Installing NVIDIA GPU stack..."
        sudo pacman -S --needed --noconfirm \
            nvidia-dkms \
            nvidia-utils \
            lib32-nvidia-utils \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "NVIDIA stack installed."
    elif [[ "$GPU_CHOICE" == "3" ]]; then
        info "Installing Intel GPU stack..."
        sudo pacman -S --needed --noconfirm \
            vulkan-intel \
            lib32-vulkan-intel \
            intel-media-driver \
            lib32-mesa \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "Intel stack installed."
    fi

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
        bluez \
        bluez-utils \
        openssh \
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
        pavucontrol

    info "Installing graphics stack..."
    info "Choose GPU vendor:"
    info "  1) AMD"
    info "  2) NVIDIA"
    info "  3) Intel"
    read -rp "Choice [1]: " GPU_CHOICE
    GPU_CHOICE="${GPU_CHOICE:-1}"
    if [[ "$GPU_CHOICE" == "1" ]]; then
        info "Installing AMD GPU stack..."
        sudo pacman -S --needed --noconfirm \
            mesa \
            vulkan-radeon \
            vulkan-intel \
            vulkan-tools \
            lib32-vulkan-radeon \
            lib32-mesa \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "AMD stack installed."
    elif [[ "$GPU_CHOICE" == "2" ]]; then
        info "Installing NVIDIA GPU stack..."
        sudo pacman -S --needed --noconfirm \
            nvidia-dkms \
            nvidia-utils \
            lib32-nvidia-utils \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "NVIDIA stack installed."
    elif [[ "$GPU_CHOICE" == "3" ]]; then
        info "Installing Intel GPU stack..."
        sudo pacman -S --needed --noconfirm \
            vulkan-intel \
            lib32-vulkan-intel \
            intel-media-driver \
            lib32-mesa \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "Intel stack installed."
    fi

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

    info "Creating default hyprland config..."
    mkdir -p $HOME/.config/hypr
    cat > $HOME/.config/hypr/hyprland.lua << 'EOF'
-- See: https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua

hl.monitor({
    output   = "",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = "1",
})

local terminal     = "kitty"
local fileManager  = "nautilus ~"
local browser      = "chromium"
local menu         = "rofi -show drun"
local cmd          = "rofi -show run"
local emoji_picker = "plasma-emojier"

hl.on("hyprland.start", function ()
    hl.exec_cmd(terminal)
    hl.exec_cmd("wl-paste -p -t text --watch clipman store -P --histpath='~/.local/share/clipman.json'")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("waybar & hyprpaper")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 6,
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
        rounding       = 4,
        rounding_power = 2,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        shadow = {
            enabled      = true,
            range        = 3,
            render_power = 2,
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
--    name        = "epic-mouse-v1",
    name        = "telink-wireless-receiver-mouse",
    sensitivity = -0.25,
})

local mainMod = "SUPER"
local secondMod = "SUPER + SHIFT"
local thirdMod = "SUPER + CTRL"
local fourthMod = "SUPER + ALT"

hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
local closeWindowBind = hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(thirdMod .. " + L", hl.dsp.exec_cmd("~/.local/bin/hyprshut"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(thirdMod .. " + E", hl.dsp.exec_cmd(emoji_picker))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("clipman pick -t rofi"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(menu))
hl.bind(thirdMod .. " + SPACE", hl.dsp.exec_cmd(cmd))
hl.bind(thirdMod .. " + E", hl.dsp.exec_cmd(emoji_picker))
hl.bind(thirdMod .. " + SPACE", hl.dsp.exec_cmd(cmd))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(secondMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
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

    info "Creating blank list clipman..."
    mkdir -p $HOME/.local/share
    cat "[]" > $HOME/.local/share/clipman.json

    info "Creating hyprshut shortcut..."
    mkdir -p $HOME/.local/bin
    cat > $HOME/.local/bin/hyprshut << 'EOF'
#!/bin/bash

command -v hyprshutdown >/dev/null 2>&1
hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
EOF
    chmod +x $HOME/.local/bin/hyprshut

    info "Creating custom env..."
    mkdir -p $HOME/.bashrc.d
    cat > $HOME/.bashrc.d/bashenv << 'EOF'
if [ -d "$HOME/bin" ] ; then
    export PATH="$HOME/bin:$PATH"
fi

if [ -z "$XDG_CONFIG_HOME" ] ; then
    export XDG_CONFIG_HOME="$HOME/.config"
fi

waybar-reload() {
    while
        inotifywait -e close_write $XDG_CONFIG_HOME/waybar;
    do
        killall -SIGUSR2 waybar;
    done
}
EOF

    info "Creating pre-config waybar..."
    mkdir -p $HOME/.config/waybar
    cat > $HOME/.config/waybar/power_menu.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<interface>
	<object class="GtkMenu" id="menu">
		<child>
			<object class="GtkMenuItem" id="logout">
				<property name="label">Log Out</property>
			</object>
		</child>
		<child>
			<object class="GtkSeparatorMenuItem" id="delimiter1"/>
		</child>
		<child>
			<object class="GtkMenuItem" id="reboot">
				<property name="label">Reboot</property>
			</object>
		</child>
		<child>
			<object class="GtkMenuItem" id="shutdown">
				<property name="label">Shutdown</property>
			</object>
		</child>
	</object>
</interface>
EOF
    cat > $HOME/.config/waybar/config.jsonc << 'EOF'
{
  "layer": "top",
  "modules-left": [
    "clock",
    "bluetooth",
    "network",
    "hyprland/workspaces",
    "hyprland/submap"
  ],
  "modules-center": [
    "hyprland/window"
  ],
  "modules-right": [
    "pulseaudio",
    "cpu",
    "memory",
    "keyboard-state",
    "custom/clipman",
    "custom/power"
  ],
  "hyprland/window": {
    "max-length": 50
  },
  "battery": {
    "interval": 60,
    "format": "{capacity}% {icon}",
    "format-icons": {
      "default": [
        "󰂎",
        "󰁺",
        "󰁻",
        "󰁼",
        "󰁽",
        "󰁾",
        "󰁿",
        "󰂀",
        "󰂁",
        "󰂂",
        "󰁹"
      ],
      "charging": [
        "󰢟",
        "󰢜",
        "󰂆",
        "󰂇",
        "󰂈",
        "󰢝",
        "󰂉",
        "󰢞",
        "󰂊",
        "󰂋",
        "󰂅"
      ]
    }
  },
  "bluetooth": {
    "format": "",
    "format-disabled": "",
    "format-connected": " {num_connections}",
    "tooltip-format": "{controller_alias}\t{controller_address}",
    "tooltip-format-connected": "{controller_alias}\t{controller_address}\n\n{device_enumerate}",
    "tooltip-format-enumerate-connected": "{device_alias}\t{device_address}",
    "on-click": "blueman-manager"
  },
  "clock": {
    "format": "{:%H:%M}  ",
    "format-alt": "{:%a, %d %b %Y (%R)}  ",
    "tooltip-format": "<tt><small>{calendar}</small></tt>",
    "calendar": {
      "mode": "month",
      "mode-mon-col": 3,
      "weeks-pos": "left",
      "on-scroll": 1,
      "format": {
        "months": "<span color='#ffead3'><b>{}</b></span>",
        "days": "<span color='#ecc6d9'><b>{}</b></span>",
        "weeks": "<span color='#99ffdd'><b>W{}</b></span>",
        "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
        "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
      }
    },
    "actions": {
      "on-click-right": "mode",
      "on-scroll-up": "shift_up",
      "on-scroll-down": "shift_down"
    }
  },
  "cpu": {
    "interval": 10,
    "format": " {}%",
    "max-length": 10
  },
  "custom/clipman": {
    "format": "🗎",
    "tooltip": true,
    "tooltip-format": "<big>Clipboard</big>\n<tt><small>Left\t: Show list</small>\n<small>Middle\t: Clear list</small></tt>",
    "on-click": "clipman pick -t rofi",
    "on-click-middle": "clipman clear --all"
  },
  "custom/power": {
    "format": "⏻",
    "tooltip": false,
    "menu": "on-click",
    "menu-file": "~/.config/waybar/power_menu.xml",
    "menu-actions": {
      "shutdown": "shutdown",
      "reboot": "reboot",
      "logout": "~/.local/bin/hyprshut"
    }
  },
  "keyboard-state": {
    "numlock": true,
    "capslock": true,
    "format": "{name} {icon}",
    "format-icons": {
      "locked": "",
      "unlocked": ""
    }
  },
  "memory": {
    "interval": 30,
    "format": "{used:0.1f}G/{total:0.1f}G "
  },
  "network": {
    "format": "",
    "format-wifi": "",
    "format-ethernet": "󰊗",
    "format-disconnected": "",
    "tooltip-format": "{ifname} via {gwaddr} 󰊗",
    "tooltip-format-wifi": "{essid} ({signalStrength}%) ",
    "tooltip-format-ethernet": "{ifname} ",
    "tooltip-format-disconnected": "Disconnected",
    "max-length": 50
  },
  "pulseaudio": {
    "format": "{volume}% {icon} {format_source}",
    "format-bluetooth": "{volume}% {icon} {format_source}",
    "format-bluetooth-muted": "󰅶 {icon} {format_source}",
    "format-muted": "󰅶 {format_source}",
    "format-source": "{volume}% ",
    "format-source-muted": "",
    "format-icons": {
      "headphone": "",
      "hands-free": "󰂑",
      "headset": "󰂑",
      "phone": "",
      "portable": "",
      "car": "",
      "default": [
        "",
        "",
        ""
      ]
    },
    "on-click": "pavucontrol"
  }
}
EOF
    cat > $HOME/.config/waybar/style.css << 'EOF'
@define-color highlight rgba(117, 241, 250, 1);
@define-color dark-9 rgba(24, 24, 27, 0.8);
@define-color dark-8 rgba(39, 39, 52, 1);
@define-color dark-7 rgba(63, 63, 70, 1);
@define-color dark-6 rgba(82, 82, 91, 1);
@define-color dark-5 rgba(113, 113, 122, 1);

* {
    /* `otf-font-awesome` is required to be installed for icons */
    /* font-family: FontAwesome, Roboto, Helvetica, Arial, sans-serif; */
    font-family: JetBrainsMono Nerd Font Propo;
    font-size: 14px;
}

window#waybar {
    background-color: @dark-9;
    /* border-bottom: 3px solid rgba(100, 114, 125, 0.5); */
    color: white;
    font-weight: 800;
    transition-property: background-color;
    transition-duration: .5s;
}

#workspaces button {
    padding: 2px;
    /* margin: 4px 0px 4px 4px; */
    margin: 5px 0px 5px 4px;
    background: transparent;
    border-radius: 4px;
    color: white;
}

#workspaces button.active {
    background: @highlight;
    color: black;
    font-weight: 800;
}

#workspaces button.urgent {
    background-color: @urgent-color;
}

#clock {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 0px 5px 8px;
}

#bluetooth {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 0px 5px 4px;
}

#network {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 4px;
}

#battery {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 0px;
}

#custom-clipman {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 0px;
}

#cpu {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 0px;
}

#keyboard-state {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 0px;
}

#pulseaudio {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 0px;
}

#memory {
    border-radius: 4px;
    padding: 5px 8px;
    background: @dark-7;
    margin: 5px 4px 5px 0px;
}

#custom-power {
    border-radius: 4px;
    padding: 5px 6px;
    background: @dark-7;
    margin: 5px 8px 5px 0px;
}
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
        bluez \
        bluez-utils \
        openssh \
        fastfetch

    info "Installing official repository packages"
    sudo pacman -S --needed --noconfirm \
        kitty \
        neovim \
        chromium \
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
        pavucontrol

    info "Installing graphics stack..."
    info "Choose GPU vendor:"
    info "  1) AMD"
    info "  2) NVIDIA"
    info "  3) Intel"
    read -rp "Choice [1]: " GPU_CHOICE
    GPU_CHOICE="${GPU_CHOICE:-1}"
    if [[ "$GPU_CHOICE" == "1" ]]; then
        info "Installing AMD GPU stack..."
        sudo pacman -S --needed --noconfirm \
            mesa \
            vulkan-radeon \
            vulkan-intel \
            vulkan-tools \
            lib32-vulkan-radeon \
            lib32-mesa \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "AMD stack installed."
    elif [[ "$GPU_CHOICE" == "2" ]]; then
        info "Installing NVIDIA GPU stack..."
        sudo pacman -S --needed --noconfirm \
            nvidia-dkms \
            nvidia-utils \
            lib32-nvidia-utils \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "NVIDIA stack installed."
    elif [[ "$GPU_CHOICE" == "3" ]]; then
        info "Installing Intel GPU stack..."
        sudo pacman -S --needed --noconfirm \
            vulkan-intel \
            lib32-vulkan-intel \
            intel-media-driver \
            lib32-mesa \
            egl-wayland \
            libva-utils \
            brightnessctl
        success "Intel stack installed."
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

info ""
sudo snapper -c root ls
sudo snapper -c home ls

info ""
success "All done! Your Arch Linux system is ready."
warn "Tip: always run paired snapshots before major changes:"
info "  sudo snapper -c root create --description 'pre-update'"
info "  sudo snapper -c home create --description 'pre-update'"
info ""
read -rp "Reboot system now ? [y/N] " reboot
if [[ "$reboot" =~ ^[Yy]$ ]]; then
    sudo reboot now
fi
