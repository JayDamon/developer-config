# Shared config (aliases, exports, PATH)
[ -f ~/.shell_common ] && source ~/.shell_common

# Tokyonight prompt with git branch
__build_zsh_prompt() {
    local git_part=""
    local branch
    if branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        local color gs
        local git_dir=$(git rev-parse --git-dir 2>/dev/null)
        gs=$(git status --porcelain 2>/dev/null)
        if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" || -f "$git_dir/MERGE_HEAD" ]]; then
            color="#ff9e64"  # orange — conflict/rebase
        elif echo "$gs" | grep -q '^[MADRC]' && echo "$gs" | grep -q '^.[MDRC?]'; then
            color="#bb9af7"  # magenta — staged + unstaged
        elif echo "$gs" | grep -q '^??'; then
            color="#f7768e"  # red — untracked files
        elif echo "$gs" | grep -q '^.[MDRC]'; then
            color="#e0af68"  # yellow — unstaged changes
        elif echo "$gs" | grep -q '^[MADRC]'; then
            color="#7dcfff"  # cyan — staged only
        else
            color="#9ece6a"  # green — clean
        fi
        git_part=" %F{${color}}(${branch})%f"
    fi
    # Shorten known paths
    local cwd="$PWD"
    if [[ -n "$WORK_WS" && "$cwd" == "$HOME/oncall"* ]]; then
        cwd="🚨 oc:${cwd#$HOME/oncall}"
    elif [[ "$cwd" == "$DOTFILES_DIR"* ]]; then
        cwd="⚙️ jdot:${cwd#$DOTFILES_DIR}"
    elif [[ -n "$WORK_WS" && "$cwd" == "$WORK_WS"* ]]; then
        cwd="🏗️ ws:${cwd#$WORK_WS}"
    elif [[ "$cwd" == "$HOME"* ]]; then
        cwd="🏠 ~${cwd#$HOME}"
    fi

    local short_host=$(hostname -s | cut -c1-12)
    PS1="%B%{[0;38;2;247;118;142m%}[%n@${short_host}]%{[0m%}%B%{[0;38;2;122;162;247m%}[${cwd}]%{[0m%}${git_part}
%{[38;2;169;177;214m%}❯%{[0m%} "
}
precmd() { __build_zsh_prompt }
setopt PROMPT_SUBST

# Fix paste issues
DISABLE_MAGIC_FUNCTIONS=true

# Ctrl+L clears screen but preserves scrollback
clear-screen-keep-scrollback() { clear -x; zle reset-prompt }
zle -N clear-screen-keep-scrollback
bindkey '^L' clear-screen-keep-scrollback

# History
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS

# Completion (deferred until first tab for speed)
autoload -Uz compinit
_lazy_compinit() {
    unfunction _lazy_compinit
    compinit -C
    zle expand-or-complete
}
zle -N expand-or-complete _lazy_compinit

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Brazil completion (lazy-loaded, work only)
if (( $+commands[brazil] )); then
_brazil_completion_lazy() {
    unfunction _brazil_completion_lazy
    [ -f ~/.brazil_completion/zsh_completion ] && source ~/.brazil_completion/zsh_completion
}
compdef _brazil_completion_lazy brazil
fi
