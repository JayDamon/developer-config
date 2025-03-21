# Configuration For New Developer Workspace
## Neovim
### Install Neovim
#### From Source
`git clone https://github.com/neovim/neovim.git`
`sudo ./install-neovim.sh`
#### From Binary
`wget https://github.com/neovim/neovim/releases/lates/download/nvim-linux64.tar.gz`
`sudo ./nvm-install.sh`
Add `export PATH="$PATH:/opt/nvim-linux64/bin"` to .bashrc/.profile/.zshrc

### Configure Neovm
`./neovim-configure.sh`
`nvim. `

### Linux Pre Req
`ripgrep` - Required for telescope.nvim

### Windows Pre Req
`ripgrep` - Required for telescope.nvim
* `winget install BurntSushi.ripgrep.MSVC`

### Styling bash shell
[Bash Shell](https://phoenixnap.com/kb/change-bash-prompt-linux)

## Intellij
### Intellij Plugins
* IdeaVim
* Fuzzier
### Configure Intellij
* Linux - `./intellij-configure.sh`
* Windows - `./intellij-configure.ps1`
