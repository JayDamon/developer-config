#!/bin/bash
DOTFILES="$(cd "$(dirname "$0")" && pwd)"

# Detect OS and set tmux prefix (Ctrl-b for mac, Ctrl-a for linux/remote)
if [[ "$(uname)" == "Darwin" ]]; then
  PREFIX="^B"
else
  PREFIX="^A"
fi

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

# Option 1 (commented out): Toggle all outer keybindings off with F12
# Uncomment the block below AND comment out Option 2 above to use instead.
# This adds prefix-less navigator on ALL systems plus an F12 toggle on mac.
#
# cat >> ~/.tmux.conf << 'NAVIGATOR'
#
# # Smart pane switching with awareness of Vim splits (prefix-less)
# is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"
# bind-key -n C-h if-shell "$is_vim" 'send-keys C-h' 'select-pane -L'
# bind-key -n C-j if-shell "$is_vim" 'send-keys C-j' 'select-pane -D'
# bind-key -n C-k if-shell "$is_vim" 'send-keys C-k' 'select-pane -U'
# bind-key -n C-l if-shell "$is_vim" 'send-keys C-l' 'select-pane -R'
# NAVIGATOR
#
# if [[ "$(uname)" == "Darwin" ]]; then
#   cat >> ~/.tmux.conf << 'TOGGLE'
#
# # F12 toggles outer tmux off for nested sessions
# bind -T root F12 \
#   set prefix None \;\
#   set key-table off \;\
#   set status-style "bg=default,fg=#565f89,dim" \;\
#   refresh-client -S
#
# bind -T off F12 \
#   set -u prefix \;\
#   set -u key-table \;\
#   set -u status-style \;\
#   refresh-client -S
# TOGGLE
# fi

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
else
  sed -i '' '/## LINUX_PLUGINS_PLACEHOLDER ##/d' ~/.tmux.conf
fi

# Install TPM if not present
if [ ! -d ~/.tmux/plugins/tpm ]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

ln -sfn "$DOTFILES/nvim" ~/.config/nvim
ln -sfn "$DOTFILES/foot" ~/.config/foot
ln -sfn "$DOTFILES/hypr" ~/.config/hypr
mkdir -p ~/.config/tmux
ln -sf "$DOTFILES/tmux/toggle-pane.sh" ~/.config/tmux/toggle-pane.sh
ln -sf "$DOTFILES/shell/.shell_common" ~/.shell_common
ln -sf "$DOTFILES/shell/.bash_profile" ~/.bash_profile
ln -sf "$DOTFILES/shell/.bashrc" ~/.bashrc
ln -sf "$DOTFILES/shell/.zshrc" ~/.zshrc
ln -sf "$DOTFILES/git/.gitconfig" ~/.gitconfig

# Environment-specific shell config
echo ""
if [ ! -f ~/.shell_work ] && [ ! -f ~/.shell_home ]; then
  read -rp "Is this a work machine? (y/n): " is_work
  if [[ "$is_work" == "y" ]]; then
    ln -sf "$DOTFILES/shell/.shell_work_early" ~/.shell_work_early
    ln -sf "$DOTFILES/shell/.shell_work" ~/.shell_work
  else
    ln -sf "$DOTFILES/shell/.shell_home" ~/.shell_home
  fi
fi

# Re-link environment configs to keep symlinks current
if [ -f ~/.shell_work ]; then
  ln -sf "$DOTFILES/shell/.shell_work_early" ~/.shell_work_early
  ln -sf "$DOTFILES/shell/.shell_work" ~/.shell_work
  [ -d "$DOTFILES/work" ] && { [ -L ~/dotfiles ] || [ ! -e ~/dotfiles ] ; } && ln -sfn "$DOTFILES/work" ~/dotfiles
  echo "Work config linked."
elif [ -f ~/.shell_home ]; then
  ln -sf "$DOTFILES/shell/.shell_home" ~/.shell_home
  echo "Home config linked."
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

echo "Dotfiles linked. (tmux prefix: $PREFIX)"

# Reload shell config
if [[ -n "$ZSH_VERSION" ]]; then
  source ~/.zshrc
elif [[ -n "$BASH_VERSION" ]]; then
  source ~/.bashrc
fi
