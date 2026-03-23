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

ln -sfn "$DOTFILES/nvim" ~/.config/nvim

echo "Dotfiles linked. (tmux prefix: $PREFIX)"
