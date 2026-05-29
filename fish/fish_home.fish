set -gx COMMON_PROFILE HOME

fish_add_path $HOME/.local/share/JetBrains/Toolbox/scripts
fish_add_path $HOME/.npm-global/bin

test -f ~/.aliases_home && source ~/.aliases_home
