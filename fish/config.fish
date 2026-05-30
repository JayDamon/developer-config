# CachyOS ships its own fish defaults (prompt, completions, etc.) — source first
if test -f /usr/share/cachyos-fish-config/cachyos-config.fish
    source /usr/share/cachyos-fish-config/cachyos-config.fish
end

# PATH (fish_add_path deduplicates and persists across sessions)
fish_add_path $HOME/.local/bin
fish_add_path $HOME/bin
fish_add_path $HOME/.cargo/bin

# DOTFILES_DIR — resolve the real path through the symlink so this works
# when ~/.config/fish/config.fish is symlinked to the repo
set -l _self (realpath (status --current-filename) 2>/dev/null)
if test -n "$_self"
    set -gx DOTFILES_DIR (realpath (dirname (dirname $_self)))
end

# Navigation shortcuts
if set -q DOTFILES_DIR
    alias jdot="cd $DOTFILES_DIR"
    alias njdot="nvim $DOTFILES_DIR"
    alias nvmsh="nvim $DOTFILES_DIR/shell"
    alias update-all="$DOTFILES_DIR/update-all.sh"
end
function ws
    if set -q WORK_WS
        cd $WORK_WS
    else
        cd $HOME/workplace
    end
end

# Machine-specific config (symlinked by install.sh)
test -f ~/.fish_home && source ~/.fish_home
test -f ~/.fish_work && source ~/.fish_work
