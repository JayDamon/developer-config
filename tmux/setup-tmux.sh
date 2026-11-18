#!/bin/bash
# setup-tmux.sh — Generate ~/.tmux.conf from tmux/.tmux.conf and link helpers.
# Used by setup-dotfiles.sh (full) and setup-minimal.sh (minimal remotes).
#
# Usage: setup-tmux.sh [default-prefix]
#   If ~/.tmux_prefix doesn't exist and a default prefix (e.g. "^B") is given,
#   it's used without prompting. Otherwise you're asked once.

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
DEFAULT_PREFIX="$1"

# Tmux prefix — ask once, persist in ~/.tmux_prefix so reruns don't re-prompt.
# Use Ctrl+A on machines you work on directly, Ctrl+B on machines accessed
# through an outer tmux session (Mac funnel, remote servers).
if [ ! -f ~/.tmux_prefix ]; then
  if [ -n "$DEFAULT_PREFIX" ]; then
    echo "$DEFAULT_PREFIX" > ~/.tmux_prefix
  else
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

mkdir -p ~/.config/tmux
ln -sf "$DOTFILES/tmux/toggle-pane.sh" ~/.config/tmux/toggle-pane.sh

# Reload any running tmux server so changes apply immediately.
tmux source-file ~/.tmux.conf 2>/dev/null || true

echo "tmux config generated. (prefix: $PREFIX)"
