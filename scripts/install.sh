#!/bin/bash

# --- Cargar definiciones de paquetes ---
source packages.sh

# 1. Instalar paquetes oficiales
sudo pacman -S --needed - < <(printf "%s\n" "${OFFICIAL_PKGS[@]}")

# 2. Instalar AUR helper
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..

# 3. Instalar paquetes AUR
paru -S --needed "${AUR_PKGS[@]}"

# 4. Configurar Zsh
#chsh -s $(which zsh)
#ln -sf ~/arch-hyprland-dotfiles/zsh/.zshrc ~/.zshrc
#ln -sf ~/arch-hyprland-dotfiles/zsh/.p10k.zsh ~/.p10k.zsh

# 5. Configurar Hyprland
mkdir -p ~/.config/hypr
cp -r .config/hypr/* ~/.config/hypr/

# 6. Configurar EWW
cp -r .config/eww/* ~/.config/eww/

# 7. Configurar gtk
cp -r .config/gtk-3.0/* ~/.config/gtk-3.0/
cp -r .config/gtk-4.0/* ~/.config/gtk-4.0/

# 8. Configurar kitty
cp -r .config/kitty/* ~/.config/kitty/

# 9. Configurar mako
cp -r .config/mako/* ~/.config/mako/

# 10. Configurar rofi
cp -r .config/rofi/* ~/.config/rofi/

# 11. Fuentes adicionales
sudo cp -r fonts/* /usr/share/fonts/
fc-cache -fv

# 12. Temas e iconos
sudo cp -r themes/* /usr/share/sddm/themes/

# 13. Scripts personalizados
sudo mkdir /etc/sddm.conf.d
sudo cp -r sddm.conf.d/*  /etc/sddm.conf.d/
