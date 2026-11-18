#!/bin/bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Tmux: generate ~/.tmux.conf (asks for prefix once), install TPM, link helpers.
bash "$DOTFILES/tmux/setup-tmux.sh"
PREFIX="$(cat ~/.tmux_prefix)"

ln -sfn "$DOTFILES/nvim" ~/.config/nvim
ln -sfn "$DOTFILES/hypr" ~/.config/hypr
ln -sfn "$DOTFILES/waybar" ~/.config/waybar
mkdir -p ~/.config/kanshi
ln -sf "$DOTFILES/hypr/kanshi.conf" ~/.config/kanshi/config
mkdir -p ~/.config/fish
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
mkdir -p ~/.config/foot
ln -sf "$DOTFILES/foot/foot.ini" ~/.config/foot/foot.ini
ln -sf "$DOTFILES/shell/.shell_common" ~/.shell_common
ln -sf "$DOTFILES/shell/.bash_profile" ~/.bash_profile
ln -sf "$DOTFILES/shell/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/shell/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/git/.gitconfig" ~/.gitconfig

# Environment-specific shell config — ask once, marker file persists the choice.
echo ""
if [ ! -f ~/.shell_work ] && [ ! -f ~/.shell_home ] && [ ! -f ~/.shell_server ]; then
  echo "Machine type:"
  echo "  h) Home"
  echo "  w) Work"
  echo "  s) Server"
  read -rp "Select [h/w/s]: " _machine_type
  case "${_machine_type}" in
    w|work)
      ln -sf "$DOTFILES/shell/.shell_work_early" ~/.shell_work_early
      ln -sf "$DOTFILES/shell/.shell_work" ~/.shell_work
      [ -f "$DOTFILES/fish/fish_work.fish" ] && ln -sf "$DOTFILES/fish/fish_work.fish" ~/.fish_work
      ;;
    s|server)
      touch ~/.shell_server
      ;;
    *)
      ln -sf "$DOTFILES/shell/.shell_home" ~/.shell_home
      ln -sf "$DOTFILES/shell/aliases_home" ~/.aliases_home
      ln -sf "$DOTFILES/fish/fish_home.fish" ~/.fish_home
      ;;
  esac
fi

# Re-link environment configs to keep symlinks current
if [ -f ~/.shell_work ]; then
  ln -sf "$DOTFILES/shell/.shell_work_early" ~/.shell_work_early
  ln -sf "$DOTFILES/shell/.shell_work" ~/.shell_work
  [ -d "$DOTFILES/work" ] && { [ -L ~/dotfiles ] || [ ! -e ~/dotfiles ] ; } && ln -sfn "$DOTFILES/work" ~/dotfiles
  [ -f "$DOTFILES/fish/fish_work.fish" ] && ln -sf "$DOTFILES/fish/fish_work.fish" ~/.fish_work
  echo "Work config linked."
  mkdir -p ~/.config/nvim
  echo 'vim.g.machine = "work"' > ~/.config/nvim/local.lua
elif [ -f ~/.shell_home ]; then
  ln -sf "$DOTFILES/shell/.shell_home" ~/.shell_home
  ln -sf "$DOTFILES/shell/aliases_home" ~/.aliases_home
  ln -sf "$DOTFILES/fish/fish_home.fish" ~/.fish_home
  echo "Home config linked."
  mkdir -p ~/.config/nvim
  echo 'vim.g.machine = "home"' > ~/.config/nvim/local.lua
elif [ -f ~/.shell_server ]; then
  echo "Server config linked."
  mkdir -p ~/.config/nvim
  echo 'vim.g.machine = "server"' > ~/.config/nvim/local.lua
fi

# First-time git identity setup
if [ ! -f ~/.gitconfig-local ]; then
  echo ""
  echo "No ~/.gitconfig-local found — setting up git identity."
  read -rp "  Git name: " git_name
  read -rp "  Git email: " git_email
  cat > ~/.gitconfig-local <<EOF
[user]
    name = $git_name
    email = $git_email
EOF
  echo "  Saved to ~/.gitconfig-local (not tracked by dotfiles)."
fi

# Bootstrap Neovim — two passes so Mason is installed before its tools are.
# Skip Mason on servers (ensure_installed is empty there anyway, and MasonToolsInstallSync
# hangs in headless mode with nothing to install).
if command -v nvim &>/dev/null; then
  echo "Bootstrapping Neovim plugins (this may take a minute)..."
  nvim --headless "+Lazy! sync" +qa 2>&1

  if [ ! -f ~/.shell_server ]; then
    echo "Installing Mason tools (LSPs, formatters — this may take several minutes)..."
    nvim --headless "+MasonToolsInstallSync" +qa 2>&1
  else
    echo "Server machine — skipping Mason tool install."
  fi

  echo "Neovim fully bootstrapped."
else
  echo "nvim not found — skipping Neovim bootstrap. Rerun setup-dotfiles.sh after installing nvim."
fi

echo "Dotfiles linked. (tmux prefix: $PREFIX)"

echo ""
echo "Reload your shell to pick up the new config:"
echo "  source ~/.bashrc   (bash)"
echo "  source ~/.zshrc    (zsh)"
echo "  exec fish          (fish)"
echo "Or just open a new terminal."
