set scrolloff=8
set number
set relativenumber
set tabstop=4 softtabstop=4
set expandtab
set smartindent

set clipboard+=unnamed
set ignorecase
set smartcase
set incsearch
set hlsearch

map <C-j> <C-W>j
map <C-k> <C-W>k
map <C-h> <C-W>h
map <C-l> <C-W>l

let mapleader = " "
nnoremap <leader>pv :Vex<CR>

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif
