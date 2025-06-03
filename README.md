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
#### Homebrew (Mac)
`brew install neovim`

### Configure Neovm
`./neovim-configure.sh`
`nvim. `

### Linux Pre Req
`ripgrep` - Required for telescope.nvim

### Windows Pre Req
`ripgrep` - Required for telescope.nvim
* `winget install BurntSushi.ripgrep.MSVC`

### Mac Pre Req
* `brew install ripgrep`

### Styling bash shell
[Bash Shell](https://phoenixnap.com/kb/change-bash-prompt-linux)

### Java Setup
- Install `cfr` which is used for decompiling Java classes
  - **Note** thhis is part of the `add-config.sh` script, but if you want to do it manually:
  - Download the JAR from [CFR's website](http://www.benf.org/other/cfr/)
    - Current version at time of writing: [CFR 0.152](http://www.benf.org/other/cfr/cfr-0.152.jar)
  - Place it in a directory like `~/.local/bin/`

## Intellij
### Intellij Plugins
* IdeaVim
* Fuzzier
### Configure Intellij
* Linux - `./intellij-configure.sh`
* Windows - `./intellij-configure.ps1`
