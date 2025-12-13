#!/bin/bash

# ------------------------------------------------------------------------------
# 0. VARIABLES Y COLORES
# ------------------------------------------------------------------------------
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_DIR="$HOME/Repositores/arch-linux-hyperland"

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}   INSTALADOR DE DOTFILES - ARCH LINUX    ${NC}"
echo -e "${BLUE}==========================================${NC}"

# ------------------------------------------------------------------------------
# 1. DEFINICIÓN DE PAQUETES (Oficiales - Pacman)
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
    "polkit-gnome"
    "grim" "slurp" "wl-clipboard" "swappy"
    "libadwaita" "gtk4-layer-shell"
    "qt5-wayland" "qt6-wayland"
    "noto-fonts" "noto-fonts-emoji" "ttf-jetbrains-mono-nerd"
)

APPS_PKGS=(
    "firefox" "vlc" "obs-studio" "discord" "steam" "krita"
    "code" "docker" "docker-compose" "jdk21-openjdk"
    "zsh" "zsh-autosuggestions" "zsh-syntax-highlighting"
    "gamemode" "lib32-gamemode" "mangohud"
)

ALL_PKGS=("${SYS_PKGS[@]}" "${HYPR_PKGS[@]}" "${APPS_PKGS[@]}")

# ------------------------------------------------------------------------------
# 2. DEFINICIÓN DE PAQUETES AUR (Paru)
# ------------------------------------------------------------------------------
AUR_PKGS=(
    "paru-bin" 
    "hyprsunset"
    "sbctl"
    "eww-git"
    "zsh-theme-powerlevel10k-git" 
    "vesktop-bin"
    "postman-bin"
    "protonup-qt"
)

# ------------------------------------------------------------------------------
# FUNCIONES DE INSTALACIÓN
# ------------------------------------------------------------------------------
install_pacman_pkgs() {
    echo -e "\n${BLUE}=== Instalando Paquetes Oficiales ===${NC}"
    echo "Sincronizando bases de datos..."
    sudo pacman -Sy

    TO_INSTALL=()
    echo "Verificando estado de los paquetes..."

    for pkg in "${ALL_PKGS[@]}"; do
        if ! pacman -Qi "$pkg" &> /dev/null; then
            TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        echo -e "${YELLOW}Paquetes a instalar (${#TO_INSTALL[@]}): ${TO_INSTALL[*]}${NC}"
        sudo pacman -S --noconfirm --needed "${TO_INSTALL[@]}"
    else
        echo -e "${GREEN}[SKIP] Todos los paquetes oficiales ya están instalados.${NC}"
    fi
}

install_aur_pkgs() {
    echo -e "\n${BLUE}=== Instalando Paquetes AUR ===${NC}"

    if ! command -v paru &> /dev/null; then
        echo -e "${YELLOW}Paru no encontrado. Instalando manualmente...${NC}"
        TEMP_DIR="$HOME/tmp_paru_install"
        mkdir -p "$TEMP_DIR"
        
        if git clone https://aur.archlinux.org/paru-bin.git "$TEMP_DIR"; then
            cd "$TEMP_DIR"
            makepkg -si --noconfirm
            cd "$HOME"
            rm -rf "$TEMP_DIR"
            echo -e "${GREEN}[OK] Paru instalado correctamente.${NC}"
        else
            echo -e "${RED}[ERROR] Falló la clonación de Paru.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}[SKIP] Paru ya está instalado.${NC}"
    fi

    echo "Verificando paquetes AUR..."
    for pkg in "${AUR_PKGS[@]}"; do
        if ! pacman -Qm "$pkg" &> /dev/null && ! pacman -Qi "$pkg" &> /dev/null; then
            echo -e "Instalando AUR: ${YELLOW}$pkg${NC}..."
            paru -S --noconfirm --needed "$pkg"
        else
            echo -e "${GREEN}[SKIP] $pkg ya está instalado.${NC}"
        fi
    done
}

# ------------------------------------------------------------------------------
# 3. LINKEO DE DOTFILES (Symlinks)
# ------------------------------------------------------------------------------
link_dotfiles() {
    echo -e "\n${BLUE}=== Configurando Dotfiles (Symlinks) ===${NC}"

    CONFIG_DIR="$HOME/.config"
    mkdir -p "$CONFIG_DIR"

    # A) Carpetas estándar
    FOLDERS_TO_LINK=("eww" "gtk-3.0" "gtk-4.0" "hypr" "kitty" "mako" "micro" "paru" "rofi")

    for folder in "${FOLDERS_TO_LINK[@]}"; do
        SRC="$REPO_DIR/$folder"
        DEST="$CONFIG_DIR/$folder"
        if [ -d "$SRC" ]; then
            if [ -d "$DEST" ] && [ ! -L "$DEST" ]; then
                mv "$DEST" "${DEST}.backup.$(date +%s)"
            fi
            echo "Enlazando: $folder"
            ln -sf "$SRC" "$DEST"
        fi
    done

    # B) ZSH
    echo "Configurando ZSH..."
    if [ -f "$REPO_DIR/zsh/.zshrc" ]; then ln -sf "$REPO_DIR/zsh/.zshrc" "$HOME/.zshrc"; fi
    if [ -f "$REPO_DIR/zsh/.p10k.zsh" ]; then ln -sf "$REPO_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"; fi

    # C) VS CODE
    echo "Configurando VS Code..."
    CODE_USER_DIR="$HOME/.config/Code - OSS/User"
    mkdir -p "$CODE_USER_DIR"
    if [ -f "$REPO_DIR/vscode/settings.json" ]; then
        if [ -f "$CODE_USER_DIR/settings.json" ] && [ ! -L "$CODE_USER_DIR/settings.json" ]; then
            mv "$CODE_USER_DIR/settings.json" "$CODE_USER_DIR/settings.json.backup"
        fi
        ln -sf "$REPO_DIR/vscode/settings.json" "$CODE_USER_DIR/settings.json"
    fi

    # D) EXTRAS (Git y Wallpapers)
    if [ -f "$REPO_DIR/.gitconfig" ]; then ln -sf "$REPO_DIR/.gitconfig" "$HOME/.gitconfig"; fi

    if [ -d "$REPO_DIR/wallpaper" ]; then
        TARGET_LINK="$HOME/Images"
        # Si ya existe carpeta real, la movemos a un lado (backup)
        if [ -d "$TARGET_LINK" ] && [ ! -L "$TARGET_LINK" ]; then
             mv "$TARGET_LINK" "${TARGET_LINK}.backup.$(date +%s)"
        fi
        ln -sf "$REPO_DIR/wallpaper" "$TARGET_LINK"
        echo " -> Wallpapers enlazados como ~/Images"
    fi
}

# ------------------------------------------------------------------------------
# 4. COPIA DE ARCHIVOS DE SISTEMA (Requiere Root)
# ------------------------------------------------------------------------------
copy_system_configs() {
    echo -e "\n${BLUE}=== Copiando Configuraciones del Sistema ===${NC}"
    
    SYS_CONFIGS="$REPO_DIR/system-configs"
    if [ ! -d "$SYS_CONFIGS" ]; then 
        echo -e "${YELLOW}[SKIP] Carpeta system-configs no encontrada.${NC}"
        return
    fi

    echo "Solicitando permisos de Root..."
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
    echo -e "${GREEN}[OK] Archivos de sistema copiados.${NC}"
}

# ------------------------------------------------------------------------------
# 5. CONFIGURACIÓN DE HARDWARE (Red, Teclado, Monitores)
# ------------------------------------------------------------------------------
setup_hardware() {
    echo -e "\n${BLUE}=== Configuración de Hardware ===${NC}"
    HYPR_DIR="$HOME/.config/hypr"
    mkdir -p "$HYPR_DIR"

    # --- A) RED (Eww) ---
    echo "Configurando Red..."
    RAW_INTERFACES=$(ip -o -4 addr show up scope global | grep -vE "docker|br-|veth|virbr")
    if [ -n "$RAW_INTERFACES" ]; then
        echo "$RAW_INTERFACES" | awk '{print "  -> " $2 " : " $4}'
        LISTA_NOMBRES=$(echo "$RAW_INTERFACES" | awk '{print $2}')
    else
        ip -o link show up | grep -v "lo" | awk -F': ' '{print "  -> " $2}'
        LISTA_NOMBRES=$(ip -o link show up | grep -v "lo" | awk -F': ' '{print $2}')
    fi

    DEFAULT_IFACE=$(echo "$LISTA_NOMBRES" | head -n1)
    echo -n "Escribe el NOMBRE de la interfaz (Enter para '$DEFAULT_IFACE'): "
    read USER_IFACE
    if [ -z "$USER_IFACE" ]; then USER_IFACE="$DEFAULT_IFACE"; fi
    
    mkdir -p "$HOME/.config/eww/scripts"
    echo "$USER_IFACE" > "$HOME/.config/eww/scripts/target_interface" 2>/dev/null || true
    echo -e "${GREEN}[OK] Interfaz '$USER_IFACE' guardada.${NC}"

    # --- B) TECLADO ---
    echo -e "\nDetectando distribución de teclado..."
    CURRENT_LAYOUT=$(localectl status | grep "X11 Layout" | awk '{print $3}')
    if [ -z "$CURRENT_LAYOUT" ]; then CURRENT_LAYOUT="us"; fi

    echo -n "Introduce tu Layout (ej: us, latam, es) [Enter para '$CURRENT_LAYOUT']: "
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
    echo -e "${GREEN}[OK] input.conf generado.${NC}"

    # --- C) MONITORES ---
    if [ ! -f "$HYPR_DIR/monitors.conf" ]; then
        echo -e "\n${BLUE}=== Configuración de Monitores ===${NC}"
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
            echo "Monitores encontrados:"
            i=1
            for mon in "${DETECTED_MONITORS[@]}"; do echo -e "  $i) $mon"; ((i++)); done
            
            echo -n "Selecciona el Monitor PRINCIPAL (Default 1): "
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

        echo -e "   -> Principal: $MON_1"
        
        # Generar monitors.conf
        cat > "$HYPR_DIR/monitors.conf" <<EOF
monitor=$MON_1,preferred,auto,1
EOF
        if [ -n "$MON_2" ]; then
            echo "monitor=$MON_2,preferred,auto-left,1" >> "$HYPR_DIR/monitors.conf"
        fi

        cat >> "$HYPR_DIR/monitors.conf" <<EOF

# WS Principal
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
# WS Secundario
workspace=6, monitor:$MON_2
workspace=7, monitor:$MON_2
workspace=8, monitor:$MON_2
workspace=9, monitor:$MON_2
workspace=10, monitor:$MON_2
workspace=98, monitor:$MON_2
EOF
        else
            cat >> "$HYPR_DIR/monitors.conf" <<EOF
# WS Secundarios (Flotantes o Futuro Monitor)
# workspace=6, monitor:DP-X
EOF
        fi
        echo -e "${GREEN}[OK] monitors.conf generado.${NC}"
    else
        echo -e "${YELLOW}[SKIP] monitors.conf ya existe.${NC}"
    fi

    # --- D) HARDWARE EXTRA ---
    if [ ! -f "$HYPR_DIR/hardware.conf" ]; then
        echo "Generando plantilla hardware.conf..."
        cat > "$HYPR_DIR/hardware.conf" <<EOF
# Configuración específica (Tabletas, Mouse, etc)
# device { name = ... }
EOF
    fi
}

# ------------------------------------------------------------------------------
# EJECUCIÓN FINAL (El pegamento que faltaba)
# ------------------------------------------------------------------------------

# 1. Instalar paquetes
install_pacman_pkgs
install_aur_pkgs

# 2. Configurar hardware (Red, Teclado, Monitores)
setup_hardware

# 3. Enlazar dotfiles y copiar configs de sistema
link_dotfiles
copy_system_configs

echo -e "\n${GREEN}==========================================${NC}"
echo -e "${GREEN}   ¡INSTALACIÓN COMPLETADA!  ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo "Es altamente recomendable reiniciar ahora."
echo "Comando: reboot"