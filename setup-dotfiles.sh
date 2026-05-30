#!/bin/bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Tmux prefix — ask once, persist in ~/.tmux_prefix so reruns don't re-prompt.
# Use Ctrl+A on machines you work on directly, Ctrl+B on machines accessed
# through an outer tmux session (Mac funnel, remote servers).
if [ ! -f ~/.tmux_prefix ]; then
  echo ""
  echo "Tmux prefix key:"
  echo "  a) Ctrl+A — this is a primary machine (you work here directly)"
  echo "  b) Ctrl+B — this is accessed via SSH through another tmux session"
  read -rp "Select [a/b]: " _prefix_choice
  if [[ "${_prefix_choice}" == "a" ]]; then
    echo "^A" > ~/.tmux_prefix
  else
    echo "^B" > ~/.tmux_prefix
  fi
fi
PREFIX="$(cat ~/.tmux_prefix)"

# Generate tmux config with correct prefix
rm -f ~/.tmux.conf
{
  echo "set -g prefix $PREFIX"
  echo ""
  tail -n +2 "$DOTFILES/tmux/.tmux.conf"
} > ~/.tmux.conf

# Option 2 (active): Only add vim-tmux-navigator on linux (inner tmux)
# Mac uses prefix-based pane switching to avoid conflicts with nested tmux
if [[ "$(uname)" != "Darwin" ]]; then
  cat >> ~/.tmux.conf << 'NAVIGATOR'

# Smart pane switching with awareness of Vim splits (prefix-less)
is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
bind-key -n C-h if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
bind-key -n C-j if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
bind-key -n C-k if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
bind-key -n C-l if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
NAVIGATOR
fi

# Linux-only: add session save/restore plugins
if [[ "$(uname)" != "Darwin" ]]; then
  sed -i '/## LINUX_PLUGINS_PLACEHOLDER ##/r /dev/stdin' ~/.tmux.conf << 'PLUGINS'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @resurrect-capture-pane-contents 'on'
set -g @resurrect-processes 'nvim vim kiro-cli'
set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'
PLUGINS
  sed -i '/## LINUX_PLUGINS_PLACEHOLDER ##/d' ~/.tmux.conf
  # Fix clipboard: Linux uses wl-copy (Wayland) or xclip (X11)
  if command -v wl-copy &>/dev/null; then
    sed -i 's/pbcopy/wl-copy/' ~/.tmux.conf
  elif command -v xclip &>/dev/null; then
    sed -i 's/pbcopy/xclip -selection clipboard/' ~/.tmux.conf
  fi
else
  sed -i '' '/## LINUX_PLUGINS_PLACEHOLDER ##/d' ~/.tmux.conf
fi

# Install TPM if not present
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

ln -sfn "$DOTFILES/nvim" ~/.config/nvim
ln -sfn "$DOTFILES/hypr" ~/.config/hypr
mkdir -p ~/.config/fish
ln -sf "$DOTFILES/fish/config.fish" ~/.config/fish/config.fish
mkdir -p ~/.config/foot
ln -sf "$DOTFILES/foot/foot.ini" ~/.config/foot/foot.ini
mkdir -p ~/.config/tmux
ln -sf "$DOTFILES/tmux/toggle-pane.sh" ~/.config/tmux/toggle-pane.sh
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

# Reload shell config
if [[ -n "$ZSH_VERSION" ]]; then
  source ~/.zshrc
elif [[ -n "$BASH_VERSION" ]]; then
  source ~/.bashrc
fi
