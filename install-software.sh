#!/bin/bash
# install-software.sh — Install development tools across platforms
# Supports: macOS (Homebrew), Arch Linux (pacman/yay), Amazon Linux (dnf + manual)
set -euo pipefail

# Cache sudo credentials upfront (avoids repeated prompts)
sudo -v

# ─── OS Detection ───────────────────────────────────────────────────────────
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)
      if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "$ID" in
          amzn|amazonlinux) echo "amzn" ;;
          arch|endeavouros|manjaro|cachyos) echo "arch" ;;
          ubuntu|debian|linuxmint|pop) echo "ubuntu" ;;
          *)
            # Fallback: check ID_LIKE for arch or debian-based distros
            case "${ID_LIKE:-}" in
              *arch*)   echo "arch" ;;
              *debian*|*ubuntu*) echo "ubuntu" ;;
              *) echo "unknown-$ID" ;;
            esac
            ;;
        esac
      else
        echo "unknown"
      fi
      ;;
    *) echo "unknown" ;;
  esac
}

OS="$(detect_os)"
echo "Detected OS: $OS"

# ─── Helpers ────────────────────────────────────────────────────────────────
command_exists() { command -v "$1" &>/dev/null; }

is_kde() { pacman -Qi plasma-workspace &>/dev/null 2>&1; }

# Returns true if nvim is installed AND is >= 0.10
nvim_is_recent() {
  command_exists nvim || return 1
  local minor
  minor=$(nvim --version 2>/dev/null | head -1 | grep -oE 'v0\.([0-9]+)' | grep -oE '[0-9]+$')
  [[ "${minor:-0}" -ge 10 ]]
}

ensure_dir() {
  mkdir -p "$1"
  # Add to PATH for this session if not already there
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

install_from_github_tar() {
  # $1 = binary name, $2 = tar URL, $3 = path inside tar (optional, defaults to $1)
  local name="$1" url="$2" bin_path="${3:-$1}"
  local dest="$HOME/bin"
  ensure_dir "$dest"

  echo "  Downloading $name..."
  local tmp
  tmp="$(mktemp -d)"
  curl -sL "$url" | tar xz -C "$tmp"
  mv "$tmp/$bin_path" "$dest/$name"
  chmod +x "$dest/$name"
  rm -rf "$tmp"
  echo "  Installed $name to $dest/$name"
}

# ─── Package Lists ──────────────────────────────────────────────────────────
# Tools installed via system package manager
COMMON_PACKAGES=(
  neovim
  tmux
  ripgrep
  fd-find
  fzf
  jq
  htop
  git
  curl
  wget
)

# Tools installed from GitHub releases (when not in package manager)
# Format: name|repo|version
GITHUB_TOOLS=(
  "lazydocker|jesseduffield/lazydocker|0.24.1"
)

# ─── Platform Installers ────────────────────────────────────────────────────
install_macos() {
  if ! command_exists brew; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  echo "Updating Homebrew..."
  brew update

  echo "Installing packages via brew..."
  # brew uses 'fd' not 'fd-find'
  local brew_packages=("${COMMON_PACKAGES[@]/fd-find/fd}")
  brew install "${brew_packages[@]}" || true

  # Brew has lazydocker in a tap
  echo "Installing lazydocker via brew..."
  brew install jesseduffield/lazydocker/lazydocker || true
}

install_arch() {
  echo "Refreshing package databases..."
  sudo pacman -Syy

  echo "Installing packages via pacman..."
  # Arch uses 'fd' not 'fd-find'
  local arch_packages=("${COMMON_PACKAGES[@]/fd-find/fd}")
  arch_packages+=(docker docker-compose docker-buildx go jdk17-openjdk bash-completion tree-sitter-cli unzip foot wl-clipboard ttf-jetbrains-mono-nerd noto-fonts-emoji openrgb liquidctl socat sshfs keyd)

  if is_kde; then
    echo "  KDE detected — adding kwallet-pam..."
    arch_packages+=(kwallet-pam)
  fi

  sudo pacman -S --needed --noconfirm "${arch_packages[@]}"

  # Configure Docker
  echo "Configuring Docker..."
  sudo systemctl enable --now docker.service
  if ! groups "$USER" | grep -q docker; then
    sudo usermod -aG docker "$USER"
    echo "  Added $USER to docker group (log out and back in to take effect)"
  fi

  # Configure RGB control (OpenRGB for RAM/GPU, liquidctl for AIO cooler)
  echo "Configuring RGB control..."
  if ! grep -q "^i2c-dev" /etc/modules-load.d/i2c.conf 2>/dev/null; then
    echo "i2c-dev" | sudo tee /etc/modules-load.d/i2c.conf > /dev/null
    echo "  Enabled i2c-dev module on boot"
  fi
  sudo modprobe i2c-dev 2>/dev/null || true
  if ! groups "$USER" | grep -q i2c; then
    sudo usermod -aG i2c "$USER"
    echo "  Added $USER to i2c group (log out and back in to take effect)"
  fi
  sudo udevadm control --reload-rules && sudo udevadm trigger

  # Configure keyd — CapsLock→Escape on laptop keyboard only (0001:0001 = i8042)
  echo "Configuring keyd..."
  sudo mkdir -p /etc/keyd
  sudo cp "$SCRIPT_DIR/keyd/default.conf" /etc/keyd/default.conf
  sudo systemctl enable --now keyd

  echo "Installing lazydocker from GitHub..."
  install_github_tools
}

install_ubuntu() {
  echo "Updating apt..."
  sudo apt-get update -qq

  local packages=(
    tmux ripgrep fzf jq htop git curl wget unzip
    fd-find build-essential nodejs npm
  )
  # tree-sitter-cli isn't in Ubuntu apt repos; install via npm after nodejs is present
  echo "Installing packages via apt..."
  sudo apt-get install -y "${packages[@]}"

  # Neovim — require 0.10+. The snap and apt versions are both outdated on most
  # Ubuntu releases, so install the pre-compiled binary from GitHub releases instead.
  if nvim_is_recent; then
    echo "  nvim $(nvim --version | head -1) already installed, skipping."
  else
    local arch
    case "$(uname -m)" in
      x86_64)  arch="x86_64" ;;
      aarch64) arch="arm64" ;;
      *) echo "  Unsupported arch for nvim binary download."; arch="" ;;
    esac
    if [[ -n "$arch" ]]; then
      echo "Installing Neovim from GitHub releases (0.10+ required)..."
      local tmp
      tmp="$(mktemp -d)"
      curl -sL "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${arch}.tar.gz" \
        | tar xz -C "$tmp"
      sudo rm -rf /opt/nvim
      sudo mv "$tmp/nvim-linux-${arch}" /opt/nvim
      sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
      rm -rf "$tmp"
    fi
  fi

  # Docker — official install script is idempotent
  if ! command_exists docker; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker "$USER"
    echo "  Added $USER to docker group (log out and back in to take effect)"
  else
    echo "  Docker already installed, skipping."
  fi

  # tree-sitter-cli — needed by nvim-treesitter to compile parsers
  if ! command_exists tree-sitter; then
    echo "Installing tree-sitter-cli via npm..."
    sudo npm install -g tree-sitter-cli
  else
    echo "  tree-sitter-cli already installed, skipping."
  fi

  # lazydocker — not in apt, install from GitHub
  install_github_tools
}

install_amzn() {
  # AL2 uses yum, AL2023+ uses dnf
  local pkg_mgr
  if command_exists dnf; then
    pkg_mgr="dnf"
  elif command_exists yum; then
    pkg_mgr="yum"
  else
    echo "ERROR: Neither dnf nor yum found."
    exit 1
  fi

  # System packages (available in AL2/AL2023 repos)
  echo "Installing system packages via $pkg_mgr..."
  local sys_packages=(tmux jq htop git curl wget)
  sudo "$pkg_mgr" install -y "${sys_packages[@]}" || true

  # Brew packages (not in yum repos or need newer versions)
  if command_exists brew; then
    echo ""
    echo "Installing packages via brew..."
    local brew_packages=(neovim ripgrep fzf fd)
    brew install "${brew_packages[@]}" jesseduffield/lazydocker/lazydocker || true
  else
    echo ""
    echo "  Homebrew is not installed."
    echo "  The following tools require brew on Amazon Linux: neovim, ripgrep, fzf, fd, lazydocker"
    echo ""
    read -rp "  Install what's possible from GitHub, or install Homebrew first? [github/brew]: " choice
    case "$choice" in
      brew|homebrew|b)
        echo ""
        echo "  ─── Install Homebrew (Linuxbrew) ───────────────────────────"
        echo ""
        echo "  Run the following command to install Homebrew:"
        echo ""
        echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo ""
        echo "  After installation, add brew to your PATH:"
        echo ""
        echo '    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"'
        echo ""
        echo "  Then re-run this script:"
        echo ""
        echo "    ./install-software.sh"
        echo ""
        echo "  ─────────────────────────────────────────────────────────────"
        exit 0
        ;;
      *)
        install_github_tools
        # fd from GitHub
        if ! command_exists fd && ! command_exists fdfind; then
          echo "  Installing fd from GitHub..."
          local arch
          case "$(uname -m)" in
            x86_64) arch="x86_64-unknown-linux-gnu" ;;
            aarch64) arch="aarch64-unknown-linux-gnu" ;;
            *) echo "  Unsupported arch for fd"; arch="" ;;
          esac
          if [[ -n "$arch" ]]; then
            local fd_ver="10.2.0"
            local fd_url="https://github.com/sharkdp/fd/releases/download/v${fd_ver}/fd-v${fd_ver}-${arch}.tar.gz"
            install_from_github_tar "fd" "$fd_url" "fd-v${fd_ver}-${arch}/fd"
          fi
        fi
        ;;
    esac
  fi
}

# ─── GitHub Release Installer ──────────────────────────────────────────────
install_github_tools() {
  ensure_dir "$HOME/bin"

  for entry in "${GITHUB_TOOLS[@]}"; do
    IFS='|' read -r name repo version <<< "$entry"

    if command_exists "$name"; then
      echo "  $name already installed, skipping."
      continue
    fi

    local arch
    case "$(uname -m)" in
      x86_64) arch="x86_64" ;;
      aarch64|arm64) arch="arm64" ;;
      *) echo "  Unsupported arch for $name"; continue ;;
    esac

    local os_str
    case "$(uname -s)" in
      Linux) os_str="Linux" ;;
      Darwin) os_str="Darwin" ;;
    esac

    case "$name" in
      lazydocker)
        local url="https://github.com/$repo/releases/download/v${version}/lazydocker_${version}_${os_str}_${arch}.tar.gz"
        install_from_github_tar "$name" "$url" "lazydocker"
        ;;
    esac
  done
}

# ─── Main ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo " Installing development tools ($OS)"
echo "═══════════════════════════════════════════"
echo ""

case "$OS" in
  macos)  install_macos ;;
  arch)   install_arch ;;
  ubuntu) install_ubuntu ;;
  amzn)   install_amzn ;;
  *)
    echo "Unsupported OS: $OS"
    echo "Supported: macOS, Arch Linux, Amazon Linux"
    exit 1
    ;;
esac

echo ""
echo "═══════════════════════════════════════════"
echo " Done! Installed tools:"
echo "═══════════════════════════════════════════"
for cmd in neovim tmux rg fd fzf jq lazydocker; do
  actual="${cmd}"
  [[ "$cmd" == "neovim" ]] && actual="nvim"
  # Ubuntu ships fd as fdfind
  [[ "$cmd" == "fd" ]] && ! command_exists fd && actual="fdfind"
  if command_exists "$actual"; then
    printf "  ✓ %-12s %s\n" "$actual" "$(command -v "$actual")"
  else
    printf "  ✗ %-12s not found\n" "$actual"
  fi
done

echo ""
echo "Note: Ensure ~/bin is in your PATH. Add to your shell config:"
echo '  export PATH="$HOME/bin:$PATH"'
