#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# 0. VARIABLES AND COLORS
# ------------------------------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   DOTFILES INSTALLER - ARCH LINUX        ${NC}"
echo -e "${BLUE}==========================================${NC}"

# ------------------------------------------------------------------------------
# 1. PACKAGE DEFINITIONS (Official - Pacman)
# ------------------------------------------------------------------------------
SYS_PKGS=(
    "base-devel" "git" "wget" "curl" "unzip" "zip" "7zip"
    "bc" "jq" "socat" "pacman-contrib" "dosfstools" "ntfs-3g"
    "networkmanager" "network-manager-applet"
    "pipewire" "pipewire-pulse" "pipewire-alsa"
    "bluez" "bluez-utils" "blueman"
    "brightnessctl" "cpupower" "zram-generator"
    "fzf" "eza" "bat" "zoxide" "plocate" "tealdeer"
    "micro" "nano" "sysstat"
    "gvfs" 
)

HYPR_PKGS=(
    "hyprland" "hypridle" "hyprlock" "hyprpaper"
    "xdg-desktop-portal-hyprland" "xdg-desktop-portal-gtk"
    "xorg-xwayland" 
    "rofi-wayland" "mako" 
    "kitty" "sddm"
    "dolphin" "ark"
    "polkit-gnome" "gnome-keyring"
    "grim" "slurp" "wl-clipboard" "swappy"
    "libadwaita" "gtk4-layer-shell"
    "qt5-wayland" "qt6-wayland"
    "noto-fonts" "noto-fonts-emoji" "ttf-jetbrains-mono-nerd"
)

APPS_PKGS=(
    "firefox" "vlc" "obs-studio" "discord" "steam" "krita"
    "code" "jdk21-openjdk" "spotify-launcher"
    "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting"
    "gamemode" "lib32-gamemode" "mangohud"
)

ALL_PKGS=("${SYS_PKGS[@]}" "${HYPR_PKGS[@]}" "${APPS_PKGS[@]}")

# ------------------------------------------------------------------------------
# 2. AUR PACKAGE DEFINITIONS (Paru)
# ------------------------------------------------------------------------------
AUR_PKGS=(
    "hyprsunset"
    "sbctl"
    "eww-git"
    "zsh-theme-powerlevel10k-git" 
    "vesktop-bin"
    "postman-bin"
    "protonup-qt"
)

# ------------------------------------------------------------------------------
# INSTALLATION FUNCTIONS
# ------------------------------------------------------------------------------
enable_multilib() {
    echo -e "\n${BLUE}=== Enabling multilib repository ===${NC}"
    if grep -q "^\[multilib\]" /etc/pacman.conf; then
        echo -e "${GREEN}[SKIP] multilib is already enabled.${NC}"
    else
        echo "Uncommenting multilib in /etc/pacman.conf..."
        sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//}' /etc/pacman.conf
        echo -e "${GREEN}[OK] multilib repository enabled.${NC}"
    fi
}

setup_gpu_drivers() {
    echo -e "\n${BLUE}=== GPU Driver Setup ===${NC}"
    echo "Select your GPU vendor:"
    echo "  1) AMD"
    echo "  2) NVIDIA"
    echo "  3) Intel"
    echo "  4) Skip (install drivers manually later)"
    echo -n "Option [1-4]: "
    read GPU_CHOICE

    case "$GPU_CHOICE" in
        1)
            GPU_PKGS=("mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon" "libva-mesa-driver" "lib32-libva-mesa-driver")
            echo -e "${YELLOW}Installing AMD drivers...${NC}"
            ;;
        2)
            GPU_PKGS=("nvidia" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings")
            echo -e "${YELLOW}Installing NVIDIA drivers...${NC}"
            ;;
        3)
            GPU_PKGS=("mesa" "lib32-mesa" "vulkan-intel" "lib32-vulkan-intel")
            echo -e "${YELLOW}Installing Intel drivers...${NC}"
            ;;
        *)
            echo -e "${YELLOW}[SKIP] GPU driver installation skipped.${NC}"
            return
            ;;
    esac

    sudo pacman -S --noconfirm --needed "${GPU_PKGS[@]}"
    echo -e "${GREEN}[OK] GPU drivers installed.${NC}"
}

install_pacman_pkgs() {
    echo -e "\n${BLUE}=== Installing Official Packages ===${NC}"
    echo "Syncing package databases..."
    sudo pacman -Syu --noconfirm

    TO_INSTALL=()
    echo "Checking package status..."

    for pkg in "${ALL_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        echo -e "${YELLOW}Packages to install (${#TO_INSTALL[@]}): ${TO_INSTALL[*]}${NC}"
        sudo pacman -S --noconfirm --needed "${TO_INSTALL[@]}"
    else
        echo -e "${GREEN}[SKIP] All official packages are already installed.${NC}"
    fi
}

install_aur_pkgs() {
    echo -e "\n${BLUE}=== Installing AUR Packages ===${NC}"

    if ! command -v paru &> /dev/null; then
        echo -e "${YELLOW}Paru not found. Installing manually...${NC}"
        TEMP_DIR="$HOME/tmp_paru_install"
        mkdir -p "$TEMP_DIR"
        
        if git clone https://aur.archlinux.org/paru-bin.git "$TEMP_DIR"; then
            cd "$TEMP_DIR"
            makepkg -si --noconfirm
            cd "$HOME"
            rm -rf "$TEMP_DIR"
            echo -e "${GREEN}[OK] Paru installed successfully.${NC}"
        else
            echo -e "${RED}[ERROR] Failed to clone Paru.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[SKIP] Paru is already installed.${NC}"
    fi

    echo "Checking AUR packages..."
    for pkg in "${AUR_PKGS[@]}"; do
        if ! pacman -Qm "$pkg" &> /dev/null && ! pacman -Qi "$pkg" &> /dev/null; then
            echo -e "Installing AUR: ${YELLOW}$pkg${NC}..."
            paru -S --noconfirm --needed "$pkg"
        else
            echo -e "${GREEN}[SKIP] $pkg is already installed.${NC}"
        fi
    done
}

# ------------------------------------------------------------------------------
# 3. DOTFILE LINKING (Symlinks)
# ------------------------------------------------------------------------------
link_dotfiles() {
    echo -e "\n${BLUE}=== Setting Up Dotfiles (Symlinks) ===${NC}"

    CONFIG_DIR="$HOME/.config"
    mkdir -p "$CONFIG_DIR"

    # A) Standard config folders
    FOLDERS_TO_LINK=("eww" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "micro" "paru" "rofi")

    for folder in "${FOLDERS_TO_LINK[@]}"; do
        SRC="$REPO_DIR/$folder"
        DEST="$CONFIG_DIR/$folder"
        if [ -d "$SRC" ]; then
            if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
                mv "$DEST" "${DEST}.backup.$(date +%s)"
            fi
            echo "Linking: $folder"
            ln -sf "$SRC" "$DEST"
        fi
    done

    # B) ZSH
    echo "Setting up ZSH..."
    if [ -f "$REPO_DIR/zsh/.zshrc" ]; then ln -sf "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"; fi
    if [ -f "$REPO_DIR/zsh/.p10k.zsh" ]; then ln -sf "$REPO_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"; fi

    # C) VS CODE
    echo "Setting up VS Code..."
    CODE_USER_DIR="$HOME/.config/Code - OSS/User"
    mkdir -p "$CODE_USER_DIR"
    if [ -f "$REPO_DIR/vscode/settings.json" ]; then
        if [ -f "$CODE_USER_DIR/settings.json" ] && [ ! -L "$CODE_USER_DIR/settings.json" ]; then
            mv "$CODE_USER_DIR/settings.json" "$CODE_USER_DIR/settings.json.backup"
        fi
        ln -sf "$REPO_DIR/vscode/settings.json" "$CODE_USER_DIR/settings.json"
    fi

    # D) EXTRAS (Git and Wallpapers)
    if [ -f "$REPO_DIR/.gitconfig" ]; then ln -sf "$REPO_DIR/.gitconfig" "$HOME/.gitconfig"; fi

    if [ -d "$REPO_DIR/wallpaper" ]; then
        TARGET_LINK="$HOME/Images"
        # Backup existing real directory if it exists
        if [ -d "$TARGET_LINK" ] && [ ! -L "$TARGET_LINK" ]; then
             mv "$TARGET_LINK" "${TARGET_LINK}.backup.$(date +%s)"
        fi
        ln -sf "$REPO_DIR/wallpaper" "$TARGET_LINK"
        echo " -> Wallpapers linked as ~/Images"
    fi
}

# ------------------------------------------------------------------------------
# 4. SYSTEM CONFIG FILES (Requires Root)
# ------------------------------------------------------------------------------
copy_system_configs() {
    echo -e "\n${BLUE}=== Copying System Configurations ===${NC}"
    
    SYS_CONFIGS="$REPO_DIR/system-configs"
    if [ ! -d "$SYS_CONFIGS" ]; then 
        echo -e "${YELLOW}[SKIP] system-configs folder not found.${NC}"
        return
    fi

    echo "Requesting Root permissions..."
    sudo -v 

    if [ -f "$SYS_CONFIGS/audio_disable_powersave.conf" ]; then
        sudo cp "$SYS_CONFIGS/audio_disable_powersave.conf" /etc/modprobe.d/
    fi

    if [ -f "$SYS_CONFIGS/gamemode.ini" ]; then
        sudo cp "$SYS_CONFIGS/gamemode.ini" /etc/gamemode.ini
    fi

    if [ -f "$SYS_CONFIGS/zram-generator.conf" ]; then
        sudo cp "$SYS_CONFIGS/zram-generator.conf" /etc/systemd/zram-generator.conf
        sudo systemctl daemon-reload
        sudo systemctl start systemd-zram-setup@zram0.service
    fi

    if [ -f "$SYS_CONFIGS/wayland.conf" ]; then
        sudo mkdir -p /etc/sddm.conf.d
        sudo cp "$SYS_CONFIGS/wayland.conf" /etc/sddm.conf.d/
    fi

    # Copy SDDM theme
    if [ -d "$REPO_DIR/themes/catppuccin-macchiato" ]; then
        sudo cp -r "$REPO_DIR/themes/catppuccin-macchiato" /usr/share/sddm/themes/
        echo -e "${GREEN}[OK] SDDM catppuccin-macchiato theme installed.${NC}"
    fi

    echo -e "${GREEN}[OK] System files copied.${NC}"
}

# ------------------------------------------------------------------------------
# 5. HARDWARE SETUP (Network, Keyboard, Monitors)
# ------------------------------------------------------------------------------
setup_hardware() {
    echo -e "\n${BLUE}=== Hardware Configuration ===${NC}"
    HYPR_DIR="$HOME/.config/hypr"
    mkdir -p "$HYPR_DIR"

    # --- A) NETWORK (Eww) ---
    echo "Configuring Network..."
    RAW_INTERFACES=$(ip -o -4 addr show up scope global | grep -vE "docker|br-|veth|virbr" || true)
    if [ -n "$RAW_INTERFACES" ]; then
        echo "$RAW_INTERFACES" | awk '{print "  -> " $2 " : " $4}'
        IFACE_NAMES=$(echo "$RAW_INTERFACES" | awk '{print $2}')
    else
        ip -o link show up | grep -v "lo" | awk -F': ' '{print "  -> " $2}'
        IFACE_NAMES=$(ip -o link show up | grep -v "lo" | awk -F': ' '{print $2}' || true)
    fi

    DEFAULT_IFACE=$(echo "$IFACE_NAMES" | head -n1)
    echo -n "Enter the interface NAME (press Enter for '$DEFAULT_IFACE'): "
    read USER_IFACE
    if [ -z "$USER_IFACE" ]; then USER_IFACE="$DEFAULT_IFACE"; fi
    
    mkdir -p "$HOME/.config/eww/scripts"
    echo "$USER_IFACE" > "$HOME/.config/eww/scripts/target_interface" 2>/dev/null || true
    echo -e "${GREEN}[OK] Interface '$USER_IFACE' saved.${NC}"

    # --- B) KEYBOARD ---
    echo -e "\nDetecting keyboard layout..."
    CURRENT_LAYOUT=$(localectl status | grep "X11 Layout" | awk '{print $3}' || true)
    if [ -z "$CURRENT_LAYOUT" ]; then CURRENT_LAYOUT="us"; fi

    echo -n "Enter your keyboard layout (e.g: us, latam, es) [Enter for '$CURRENT_LAYOUT']: "
    read USER_KB_LAYOUT
    if [ -z "$USER_KB_LAYOUT" ]; then USER_KB_LAYOUT="$CURRENT_LAYOUT"; fi

    sudo localectl set-x11-keymap "$USER_KB_LAYOUT" 2>/dev/null
    
    cat > "$HYPR_DIR/input.conf" <<EOF
input {
    kb_layout = $USER_KB_LAYOUT
    follow_mouse = 1
    accel_profile = flat
    force_no_accel = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
    }
}
EOF
    echo -e "${GREEN}[OK] input.conf generated.${NC}"

    # --- C) MONITORS ---
    if [ ! -f "$HYPR_DIR/monitors.conf" ]; then
        echo -e "\n${BLUE}=== Monitor Configuration ===${NC}"
        DETECTED_MONITORS=()
        for connector in /sys/class/drm/card*-*; do
            if [ -f "$connector/status" ] && [ "$(cat "$connector/status")" == "connected" ]; then
                raw_name=$(basename "$connector")
                clean_name=$(echo "$raw_name" | sed 's/^card[0-9]-//')
                DETECTED_MONITORS+=("$clean_name")
            fi
        done

        if [ ${#DETECTED_MONITORS[@]} -eq 0 ]; then
            MON_1="HDMI-A-1"; MON_2="DP-1"
        else
            echo "Detected monitors:"
            i=1
            for mon in "${DETECTED_MONITORS[@]}"; do echo -e "  $i) $mon"; ((i++)) || true; done
            
            echo -n "Select PRIMARY monitor (Default 1): "
            read SELECTION
            if [ -z "$SELECTION" ]; then SELECTION=1; fi
            INDEX=$((SELECTION - 1))
            MON_1=${DETECTED_MONITORS[INDEX]}
            if [ -z "$MON_1" ]; then MON_1=${DETECTED_MONITORS[0]}; fi

            MON_2=""
            for mon in "${DETECTED_MONITORS[@]}"; do
                if [ "$mon" != "$MON_1" ]; then MON_2="$mon"; break; fi
            done
        fi

        echo -e "   -> Primary: $MON_1"
        
        # Generate monitors.conf
        cat > "$HYPR_DIR/monitors.conf" <<EOF
monitor=$MON_1,preferred,auto,1
EOF
        if [ -n "$MON_2" ]; then
            echo "monitor=$MON_2,preferred,auto-left,1" >> "$HYPR_DIR/monitors.conf"
        fi

        cat >> "$HYPR_DIR/monitors.conf" <<EOF

# Primary Monitor Workspaces
workspace=1, monitor:$MON_1
workspace=2, monitor:$MON_1
workspace=3, monitor:$MON_1
workspace=4, monitor:$MON_1
workspace=5, monitor:$MON_1
workspace=99, monitor:$MON_1

workspace = 1, gapsin:5, gapsout:55 5 5 5
workspace = 2, gapsin:5, gapsout:55 5 5 5
workspace = 3, gapsin:5, gapsout:55 5 5 5
workspace = 4, gapsin:5, gapsout:55 5 5 5
workspace = 5, gapsin:5, gapsout:55 5 5 5
EOF
        if [ -n "$MON_2" ]; then
            cat >> "$HYPR_DIR/monitors.conf" <<EOF
# Secondary Monitor Workspaces
workspace=6, monitor:$MON_2
workspace=7, monitor:$MON_2
workspace=8, monitor:$MON_2
workspace=9, monitor:$MON_2
workspace=10, monitor:$MON_2
workspace=98, monitor:$MON_2
EOF
        else
            cat >> "$HYPR_DIR/monitors.conf" <<EOF
# Secondary Workspaces (Floating or Future Monitor)
# workspace=6, monitor:DP-X
EOF
        fi
        echo -e "${GREEN}[OK] monitors.conf generated.${NC}"
    else
        echo -e "${YELLOW}[SKIP] monitors.conf already exists.${NC}"
        # Read existing primary monitor name from monitors.conf
        MON_1=$(grep -m1 '^monitor=' "$HYPR_DIR/monitors.conf" | cut -d',' -f1 | cut -d'=' -f2)
    fi

    # --- E) UPDATE EWW BAR MONITOR ---
    if [ -n "$MON_1" ]; then
        EWW_YUCK="$HOME/.config/eww/eww.yuck"
        if [ -f "$EWW_YUCK" ]; then
            sed -i "s/:monitor \"[^\"]*\"/:monitor \"$MON_1\"/g" "$EWW_YUCK"
            echo -e "${GREEN}[OK] Eww bar monitor set to '$MON_1'.${NC}"
        fi
    fi

    # --- D) EXTRA HARDWARE ---
    if [ ! -f "$HYPR_DIR/hardware.conf" ]; then
        echo "Generating hardware.conf template..."
        cat > "$HYPR_DIR/hardware.conf" <<EOF
# Device-specific configuration (Tablets, Mouse, etc)
# device { name = ... }
EOF
    fi
}

# ------------------------------------------------------------------------------
# 6. ENABLE ESSENTIAL SERVICES
# ------------------------------------------------------------------------------
enable_services() {
    echo -e "\n${BLUE}=== Enabling Essential Services ===${NC}"
    sudo systemctl enable NetworkManager
    sudo systemctl enable bluetooth
    sudo systemctl enable sddm

    # Change default shell to ZSH
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        echo "Changing default shell to ZSH..."
        chsh -s /usr/bin/zsh
        echo -e "${GREEN}[OK] Shell changed to ZSH (will apply on next login).${NC}"
    else
        echo -e "${GREEN}[SKIP] ZSH is already the default shell.${NC}"
    fi

    echo -e "${GREEN}[OK] Services enabled.${NC}"
}

# ------------------------------------------------------------------------------
# FINAL EXECUTION
# ------------------------------------------------------------------------------

# 1. Enable multilib and install packages
enable_multilib
install_pacman_pkgs
install_aur_pkgs
setup_gpu_drivers

# 2. Link dotfiles and copy system configs
link_dotfiles
copy_system_configs

# 3. Configure hardware (Network, Keyboard, Monitors)
setup_hardware

# 4. Enable services
enable_services

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}   INSTALLATION COMPLETE!  ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo "It is highly recommended to reboot now."
echo "Command: reboot"