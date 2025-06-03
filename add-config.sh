#!/bin/bash

echo "Please select your llm tool of choice:"
select choice in "CoPilot" "Amazon Q"; do
	case $choice in
		"CoPilot")
			llm="copilot"
			echo "You selected CoPilot."
			break
			;;
		"Amazon Q")
			llm="amazon-q"
			echo "You selected Amazon Q."
			break
			;;
		*)
			echo "Invalid choice, please try again."
			continue
			;;
	esac
done

cp ./config/.ideavimrc ~/
cp ./config/.vimrc ~/
cp ./config/.tmux.conf ~/

if [ ! -d "$HOME/.config/nvim" ]; then
	mkdir -p "$HOME"/.config/nvim
	git clone https://github.com/JayDamon/nvim-config.git "$HOME"/.config/nvim
else
	cwd=$(pwd)
	cd ~/.config/nvim || exit
	git pull
	cd "$cwd" || exit
fi

echo "Setting selected llm to $llm"
sed -i "s/^_G\.llm = \".*\"/_G.llm = \"$llm\"/" "$HOME"/.config/nvim/init.lua

if [ ! -f ~/.local/bin/cfr.jar ]; then
	wget -c https://www.benf.org/other/cfr/cfr-0.152.jar -O ~/.local/bin/cfr.jar
fi 
