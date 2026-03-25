# Shared config (aliases, exports, PATH)
[ -f ~/.shell_common ] && source ~/.shell_common

# Tokyonight prompt with git branch
__build_prompt() {
    local git_part=""
    local branch
    if branch=$(git symbolic-ref --short HEAD 2>/dev/null); then
        local color
        local git_dir=$(git rev-parse --git-dir 2>/dev/null)
        local gs=$(git status --porcelain 2>/dev/null)
        if [[ -d "$git_dir/rebase-merge" || -d "$git_dir/rebase-apply" || -f "$git_dir/MERGE_HEAD" ]]; then
            color="38;2;255;158;100"  # orange — conflict/rebase
        elif echo "$gs" | grep -q '^[MADRC]' && echo "$gs" | grep -q '^.[MDRC?]'; then
            color="38;2;187;154;247"  # magenta — staged + unstaged
        elif echo "$gs" | grep -q '^??' ; then
            color="38;2;247;118;142"  # red — untracked files
        elif echo "$gs" | grep -q '^.[MDRC]' ; then
            color="38;2;224;175;104"  # yellow — unstaged changes
        elif echo "$gs" | grep -q '^[MADRC]' ; then
            color="38;2;125;207;255"  # cyan — staged only
        else
            color="38;2;158;206;106"  # green — clean
        fi
        git_part=" \[\e[${color}m\](${branch})\[\e[0m\]"
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
    if [[ "$(uname)" == "Darwin" ]]; then
        PS1="\[\e[38;2;122;162;247m\]${cwd}\[\e[0m\]${git_part}\n\[\e[38;2;169;177;214m\]❯\[\e[0m\] "
    else
        local short_host=$(hostname -s | cut -c1-12)
        PS1="\[\e[1m\][\[\e[0;38;2;247;118;142m\]\u@${short_host}\[\e[0;1m\]]\[\e[0m\] \[\e[1m\][\[\e[0;38;2;122;162;247m\]${cwd}\[\e[0;1m\]]\[\e[0m\]${git_part}\n\[\e[38;2;169;177;214m\]❯\[\e[0m\] "
    fi
}
PROMPT_COMMAND='__build_prompt; history -a'

# Ctrl+L clears screen but preserves scrollback
[[ $- == *i* ]] && bind -x '"\C-l": clear -x'

# History
HISTSIZE=1000000
HISTFILESIZE=1000000

# Brazil completion (lazy-loaded, work only)
if command -v brazil &>/dev/null; then
_brazil_completion_lazy() {
    unset -f _brazil_completion_lazy
    complete -r brazil 2>/dev/null
    [ -f ~/.brazil_completion/bash_completion ] && source ~/.brazil_completion/bash_completion
    return 124
}
complete -F _brazil_completion_lazy brazil
fi
