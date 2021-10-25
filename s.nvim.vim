" .config/nvim/init.vim
if empty(glob("~/.local/share/nvim/site/autoload/plug.vim"))
  !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
endif

call plug#begin('~/.vim/plugged')
Plug 'morhetz/gruvbox'
call plug#end()

set background=dark
colorscheme gruvbox

set mouse=a
set number
set ruler
set cursorline
set shiftwidth=4
set expandtab
