# Arch Linux + Hyprland Dotfiles

Personal dotfiles for an Arch Linux desktop running **Hyprland** as the Wayland compositor, with **systemd-boot** and **Secure Boot** enabled.

![Catppuccin Mocha](https://img.shields.io/badge/theme-Catppuccin%20Mocha-cba6f7?style=flat-square)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-89b4fa?style=flat-square)
![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-1793d1?style=flat-square)

## What's Included

| Directory | Description |
|---|---|
| `hypr/` | Hyprland, Hypridle, Hyprpaper configs |
| `eww/` | Eww bar (3 bars: left, center, right) with widgets for CPU, RAM, network, battery, volume, workspaces, and a power manager |
| `kitty/` | Terminal emulator config |
| `rofi/` | Application launcher (rofi-wayland) |
| `mako/` | Notification daemon |
| `zsh/` | ZSH config with Powerlevel10k, fzf, zoxide, syntax highlighting |
| `gtk-3.0/` / `gtk-4.0/` | GTK theme settings (Adwaita-dark) |
| `micro/` | Micro text editor config |
| `vscode/` | VS Code base settings |
| `themes/` | SDDM login theme (Catppuccin Macchiato) |
| `system-configs/` | System-level configs (ZRAM, audio, gamemode, SDDM Wayland) |
| `wallpaper/` | Desktop wallpaper |
| `install.sh` | Automated installer script |

## Quick Install (Existing Arch Installation)

> [!IMPORTANT]
> This script is designed for a **fresh Arch Linux installation** with an active internet connection. It will install packages, create symlinks, and enable system services.

```bash
git clone https://github.com/YOUR_USERNAME/arch-linux-hyperland.git ~/Repositores/arch-linux-hyperland
cd ~/Repositores/arch-linux-hyperland
chmod +x install.sh
./install.sh
```

The installer will:
1. Enable the `multilib` repository (required for 32-bit Steam/gaming packages)
2. Update the system and install all official + AUR packages
3. Ask you to select your **GPU vendor** (AMD / NVIDIA / Intel) and install the appropriate drivers
4. Symlink all dotfiles to `~/.config/`
5. Copy system configs (ZRAM, SDDM theme, audio, gamemode)
6. Detect and configure your **network interface**, **keyboard layout**, and **monitors**
7. Automatically set the Eww bar to use your primary monitor
8. Enable essential services (NetworkManager, Bluetooth, SDDM)
9. Set ZSH as the default shell

After installation, **reboot** to start SDDM and log into Hyprland.

---

## Arch Linux Installation Guide (with Secure Boot)

This guide explains how to install Arch Linux from scratch with **systemd-boot** and **Secure Boot** enabled using `sbctl`. No GRUB.

### Prerequisites

- A USB drive with the [Arch Linux ISO](https://archlinux.org/download/)
- UEFI firmware with Secure Boot support
- Internet connection (Ethernet recommended)

### 1. Boot and Connect

Boot from the USB in UEFI mode. Disable Secure Boot temporarily in BIOS for the installation.

```bash
# Connect to WiFi (skip if using Ethernet)
iwctl
> station wlan0 connect "SSID"

# Verify connection
ping -c 3 archlinux.org

# Sync clock
timedatectl set-ntp true
```

### 2. Partition the Disk

Use `fdisk` or `cfdisk` to create the partitions. This is the recommended layout:

| Partition | Type | Size | Mount Point |
|---|---|---|---|
| EFI | EFI System (FAT32) | 1 GB | `/efi` |
| Swap | Linux Swap | RAM size | `[SWAP]` |
| Root | Linux Filesystem (ext4) | Rest | `/` |

> [!NOTE]
> If dual-booting with Windows, the EFI partition may already exist. You can reuse it if it has enough space (at least 512 MB recommended), or create a separate one.
>
> Device names vary by hardware: NVMe drives use `/dev/nvme0n1pX`, SATA drives use `/dev/sdaX`. Use `lsblk` to identify your disk.

```bash
# Identify your disk
lsblk

# Format partitions (replace /dev/sdXn with your actual partition names)
mkfs.fat -F32 /dev/sdX1    # EFI partition
mkfs.ext4 /dev/sdX3        # Root partition
mkswap /dev/sdX2           # Swap partition
```

### 3. Mount Partitions

This uses a **bind mount** strategy so the kernel and initramfs live inside the ESP under `/efi/EFI/arch`, and `/boot` is a bind mount to that path. This keeps everything in the ESP for Secure Boot signing.

```bash
# Mount root (replace with your actual partition names)
mount /dev/sdX3 /mnt

# Mount ESP
mkdir -p /mnt/efi
mount /dev/sdX1 /mnt/efi

# Create the arch directory inside the ESP and bind mount it to /boot
mkdir -p /mnt/efi/EFI/arch
mkdir -p /mnt/boot
mount --bind /mnt/efi/EFI/arch /mnt/boot

# Enable swap
swapon /dev/sdX2
```

### 4. Install Base System

```bash
pacstrap -K /mnt base linux linux-firmware amd-ucode base-devel git nano networkmanager
```

> [!TIP]
> Replace `amd-ucode` with `intel-ucode` if you have an Intel CPU.

### 5. Generate fstab

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

Then **edit** `/mnt/etc/fstab` to add the bind mount manually, since `genfstab` may not capture it. Make sure it contains:

```fstab
# Root partition
UUID=<your-root-uuid>   /       ext4    rw,relatime     0 1

# ESP
UUID=<your-esp-uuid>    /efi    vfat    rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro 0 2

# Bind mount: /efi/EFI/arch -> /boot
/efi/EFI/arch           /boot   none    bind            0 0

# Swap
UUID=<your-swap-uuid>   none    swap    defaults        0 0
```

### 6. Chroot and Configure

```bash
arch-chroot /mnt

# Timezone
ln -sf /usr/share/zoneinfo/America/Mexico_City /etc/localtime
hwclock --systohc

# Locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Hostname
echo "your-hostname" > /etc/hostname

# Root password
passwd

# Create your user
useradd -m -G wheel -s /bin/bash your-username
passwd your-username

# Enable sudo for wheel group
EDITOR=nano visudo
# Uncomment: %wheel ALL=(ALL:ALL) ALL
```

### 7. Install systemd-boot

```bash
bootctl install
```

Create the boot entry at `/efi/loader/entries/arch.conf`:

```ini
title   Arch Linux
linux   /EFI/arch/vmlinuz-linux
initrd  /EFI/arch/amd-ucode.img
initrd  /EFI/arch/initramfs-linux.img
options root=UUID=<your-root-uuid> rw
```

> [!IMPORTANT]
> Replace `amd-ucode.img` with `intel-ucode.img` if you have an Intel CPU.

Edit `/efi/loader/loader.conf`:

```ini
default arch.conf
timeout 3
console-mode max
editor  no
```

### 8. Enable NetworkManager and Reboot

```bash
systemctl enable NetworkManager
exit
umount -R /mnt
reboot
```

Remove the USB and boot into your new Arch installation. Secure Boot should still be **disabled** at this point.

### 9. Set Up Secure Boot with sbctl

After booting into Arch, install and configure `sbctl`:

```bash
# Install sbctl from AUR (install paru first)
git clone https://aur.archlinux.org/paru-bin.git /tmp/paru
cd /tmp/paru && makepkg -si --noconfirm
paru -S sbctl

# Check Secure Boot status (should show Setup Mode)
sbctl status

# Create and enroll your keys (keeping Microsoft keys for dual-boot)
sbctl create-keys
sbctl enroll-keys -m

# Sign the bootloader and kernel
sbctl sign -s /efi/EFI/systemd/systemd-bootx64.efi
sbctl sign -s /efi/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/vmlinuz-linux

# Verify everything is signed
sbctl verify
```

> [!WARNING]
> The `-m` flag in `sbctl enroll-keys -m` keeps Microsoft's keys enrolled. This is **required** if dual-booting with Windows. Without it, Windows will not boot.

Now go into BIOS and **enable Secure Boot**. Your system should boot normally with Secure Boot active.

> [!TIP]
> `sbctl` includes pacman hooks that **automatically re-sign** the kernel and bootloader after updates. No manual intervention needed.

### 10. Install Dotfiles

Once booted with Secure Boot enabled, clone this repo and run the installer:

```bash
git clone https://github.com/YOUR_USERNAME/arch-linux-hyperland.git ~/Repositores/arch-linux-hyperland
cd ~/Repositores/arch-linux-hyperland
chmod +x install.sh
./install.sh
reboot
```

---

## Key Bindings

| Key | Action |
|---|---|
| `Super + Q` | Open terminal (Kitty) |
| `Super + R` | Open app launcher (Rofi) |
| `Super + E` | Open file manager (Dolphin) |
| `Super + F` | Open Firefox |
| `Super + C` | Close active window |
| `Super + V` | Toggle floating |
| `Super + Tab` | Toggle fullscreen |
| `Super + 1-0` | Switch workspace |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Arrow Keys` | Move focus |
| `Super + F9` | Enable night light (Hyprsunset) |
| `Super + F10` | Disable night light |

## Packages

<details>
<summary><strong>System Packages (pacman)</strong></summary>

`base-devel` `git` `wget` `curl` `unzip` `zip` `7zip` `bc` `jq` `socat` `pacman-contrib` `dosfstools` `ntfs-3g` `networkmanager` `network-manager-applet` `pipewire` `pipewire-pulse` `pipewire-alsa` `bluez` `bluez-utils` `blueman` `brightnessctl` `cpupower` `zram-generator` `fzf` `eza` `bat` `zoxide` `plocate` `tealdeer` `micro` `nano` `sysstat` `gvfs`

</details>

<details>
<summary><strong>Hyprland Packages (pacman)</strong></summary>

`hyprland` `hypridle` `hyprlock` `hyprpaper` `xdg-desktop-portal-hyprland` `xdg-desktop-portal-gtk` `xorg-xwayland` `rofi-wayland` `mako` `kitty` `sddm` `dolphin` `ark` `polkit-gnome` `gnome-keyring` `grim` `slurp` `wl-clipboard` `swappy` `libadwaita` `gtk4-layer-shell` `qt5-wayland` `qt6-wayland` `noto-fonts` `noto-fonts-emoji` `ttf-jetbrains-mono-nerd`

</details>

<details>
<summary><strong>Apps (pacman)</strong></summary>

`firefox` `vlc` `obs-studio` `discord` `steam` `krita` `code` `jdk21-openjdk` `spotify-launcher` `zsh` `zsh-autosuggestions` `zsh-syntax-highlighting` `gamemode` `lib32-gamemode` `mangohud`

</details>

<details>
<summary><strong>AUR Packages (paru)</strong></summary>

`hyprsunset` `sbctl` `eww-git` `zsh-theme-powerlevel10k-git` `vesktop-bin` `postman-bin` `protonup-qt`

</details>

<details>
<summary><strong>GPU Drivers (selected during install)</strong></summary>

| Vendor | Packages |
|---|---|
| AMD | `mesa` `lib32-mesa` `vulkan-radeon` `lib32-vulkan-radeon` `libva-mesa-driver` `lib32-libva-mesa-driver` |
| NVIDIA | `nvidia` `nvidia-utils` `lib32-nvidia-utils` `nvidia-settings` |
| Intel | `mesa` `lib32-mesa` `vulkan-intel` `lib32-vulkan-intel` |

</details>

## License

This is a personal dotfiles repository. Feel free to use it as reference or fork it for your own setup.
