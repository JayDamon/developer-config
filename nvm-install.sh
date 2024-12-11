#!/bin/bash

if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
    exit
fi

apt update
apt install -y make ninja-build gettext cmake unzip curl build-essential

cd neovim
make install
make CMAKE_BUILD_TYPE=Release

echo "Make installed, you can now run neovim-config.sh"
