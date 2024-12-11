#!/bin/bash

cd neovim
cmake --build build/ --target uninstall

rm -r ~/.config/nvim
rm -r ~/.local/share/nvim
