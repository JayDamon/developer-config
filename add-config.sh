#!/bin/bash

cp ./config/.ideavimrc ~/
cp ./config/.vimrc ~/
cp ./config/.tmux.conf ~/

if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p $HOME/.config/nvim
	git clone https://github.com/JayDamon/nvim-config.git $HOME/.config/nvim
else
	cwd=$(pwd)
	cd ~/.config/nvim
	git pull
	cd $cwd
fi
