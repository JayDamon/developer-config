#!/bin/bash
# hyprland-software.sh — Install the Hyprland desktop environment stack.
# Idempotent: safe to rerun. pacman/yay --needed skips already-installed packages.
set -euo pipefail

sudo -v

command_exists() { command -v "$1" &>/dev/null; }

# ─── Package Lists ───────────────────────────────────────────────────────────
# Add new official packages here — rerunning the script picks them up safely.
PACMAN_PACKAGES=(
  # Compositor + lock/idle
  hyprland
  hyprlock
  hypridle

  # Portals + Qt Wayland support
  xdg-desktop-portal-hyprland
  xdg-user-dirs
  qt5-wayland
  qt6-wayland
  qt6ct
  kvantum

  # Status bar + launcher + file manager
  waybar
  rofi-wayland
  dolphin

  # Display manager
  sddm

  # Auth + wallet (pam_kwallet_init is exec-once'd in hyprland.conf)
  polkit-gnome
  kwallet-pam

  # Monitor layout management (hotplug profiles)
  kanshi

  # Screenshots
  grim
  slurp

  # Hardware controls (brightness, media keys, volume via wpctl)
  brightnessctl
  playerctl
  wireplumber
  pipewire
  pipewire-pulse

  # Screenshots
  hyprshot

  # Power menu (used in keybinds)
  hyprshutdown

  # Browser
  brave-bin

  # Bluetooth GUI
  blueman

  # Apps / misc
  flatpak
)

# ─── Install ─────────────────────────────────────────────────────────────────
echo ""
echo "════════════════════════════════════════════"
echo " Installing Hyprland packages"
echo "════════════════════════════════════════════"
echo ""

echo "Refreshing package databases..."
sudo pacman -Syy

echo "Installing official packages via pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_PACKAGES[@]}"

# ─── SDDM ────────────────────────────────────────────────────────────────────
if [ -e /etc/systemd/system/display-manager.service ]; then
  current=$(basename "$(readlink /etc/systemd/system/display-manager.service)" .service)
  echo "Display manager already configured ($current) — skipping SDDM setup."
  echo "Note: $current should support Hyprland sessions. If not, run: sudo systemctl enable --force sddm"
else
  echo "Enabling SDDM display manager..."
  sudo systemctl enable sddm
fi

# ─── Flatpak apps ────────────────────────────────────────────────────────────
echo "Setting up Flathub and installing Flatpak apps..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.videolan.VLC

# ─── XDG user dirs ───────────────────────────────────────────────────────────
xdg-user-dirs-update

sudo systemctl enable --now bluetooth

echo ""
echo "════════════════════════════════════════════"
echo " Hyprland stack installed."
echo " Reboot and select Hyprland from SDDM."
echo "════════════════════════════════════════════"
