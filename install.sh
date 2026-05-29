#!/bin/bash
# install.sh — Orchestrates a full system setup.
# Run with no args for interactive prompts, or pass flags to skip them.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Usage ──────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  No options   Interactive prompts for each step
  -s           Install/update system packages  (install-software.sh)
  -H           Install Hyprland packages        (hyprland-software.sh)
  -d           Set up dotfile symlinks          (setup-dotfiles.sh)
  -a           Run all three steps
  -r           Refresh: auto-detect environment, run everything needed
  -h           Show this help

Examples:
  ./install.sh          # interactive
  ./install.sh -a       # install everything
  ./install.sh -s -d    # packages + dotfiles, skip Hyprland
  ./install.sh -r       # smart refresh (includes Hyprland only if detected)
EOF
}

# ─── Flags ──────────────────────────────────────────────────────────────────
do_software=false
do_hyprland=false
do_dotfiles=false
refresh=false
interactive=true

while getopts ":sHdarh" opt; do
  case "$opt" in
    s) do_software=true; interactive=false ;;
    H) do_hyprland=true; interactive=false ;;
    d) do_dotfiles=true; interactive=false ;;
    a) do_software=true; do_hyprland=true; do_dotfiles=true; interactive=false ;;
    r) refresh=true; interactive=false ;;
    h) usage; exit 0 ;;
    \?) echo "Unknown option: -$OPTARG"; usage; exit 1 ;;
  esac
done

# ─── Hyprland Detection ──────────────────────────────────────────────────────
hyprland_detected() {
  # Running as the active session
  [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" ]] && return 0
  [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]     && return 0
  # Installed but not necessarily running (e.g. called from TTY)
  command -v Hyprland &>/dev/null                 && return 0
  return 1
}

# ─── Refresh Mode ────────────────────────────────────────────────────────────
if $refresh; then
  do_software=true
  do_dotfiles=true
  if hyprland_detected; then
    echo "Hyprland detected — including Hyprland packages."
    do_hyprland=true
  else
    echo "Hyprland not detected — skipping Hyprland packages."
  fi
fi

# ─── Interactive Prompts ─────────────────────────────────────────────────────
if $interactive; then
  echo ""
  echo "════════════════════════════════════════════"
  echo " System Setup"
  echo "════════════════════════════════════════════"
  echo ""

  read -rp "Install/update system packages? (y/n): " ans
  [[ "$ans" == "y" ]] && do_software=true

  read -rp "Install Hyprland packages?       (y/n): " ans
  [[ "$ans" == "y" ]] && do_hyprland=true

  read -rp "Set up dotfile symlinks?         (y/n): " ans
  [[ "$ans" == "y" ]] && do_dotfiles=true

  echo ""
fi

# ─── Run Steps ───────────────────────────────────────────────────────────────
if ! $do_software && ! $do_hyprland && ! $do_dotfiles; then
  echo "Nothing selected. Exiting."
  exit 0
fi

$do_software && bash "$SCRIPT_DIR/install-software.sh"
$do_hyprland && bash "$SCRIPT_DIR/hyprland-software.sh"
$do_dotfiles && bash "$SCRIPT_DIR/setup-dotfiles.sh"

echo ""
echo "════════════════════════════════════════════"
echo " Setup complete."
echo "════════════════════════════════════════════"
