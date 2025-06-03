COPY-ITEM ".\config\.ideavimrc" -Destination "~\"
COPY-ITEM ".\config\.vimrc" -Destination "~\"

New-Item -ItemType Directory -Force $HOME\AppData\Local\nvim

git clone https://github.com/JayDamon/nvim-config.git $HOME\AppData\Local\nvim\
