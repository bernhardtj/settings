" .vimrc
if has('gui_running')
    silent !bash -c 'test -e "$HOME/.vim/colors/solarized.vim" || (mkdir -p "$HOME/.vim/colors" && curl -sLo "$HOME/.vim/colors/solarized.vim" https://raw.githubusercontent.com/altercation/vim-colors-solarized/master/colors/solarized.vim)'
    set guifont=Fira\ Code\ 12
    colorscheme solarized
    set background=light
else
    set mouse=a
endif
