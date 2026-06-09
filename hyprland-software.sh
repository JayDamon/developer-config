#!/bin/bash
# hyprland-software.sh — Install the Hyprland desktop environment stack.
# Idempotent: safe to rerun. pacman/yay --needed skips already-installed packages.
set -euo pipefail

sudo -v

command_exists() { command -v "$1" &>/dev/null; }

# ─── AUR Helper ──────────────────────────────────────────────────────────────
# Builds and installs yay-bin from AUR if no AUR helper is present.
# On CachyOS yay ships pre-installed; this handles bare Arch.
ensure_aur_helper() {
  if command_exists yay || command_exists paru; then
    return 0
  fi
  echo "No AUR helper found — building yay-bin from AUR..."
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

aur_install() {
  if command_exists yay; then
    yay -S --needed --noconfirm "$@"
  elif command_exists paru; then
    paru -S --needed --noconfirm "$@"
  fi
}

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

  # Apps / misc
  flatpak
)

# Add new AUR packages here — rerunning picks them up safely.
AUR_PACKAGES=(
  hyprshot      # screenshot tool (used in keybinds)
  hyprshutdown  # power menu (used in keybinds)
  brave-bin     # browser
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

ensure_aur_helper

echo "Installing AUR packages..."
aur_install "${AUR_PACKAGES[@]}"

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
