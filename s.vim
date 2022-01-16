" .vimrc

function EnsurePackage(pkg)
    if empty(glob('~/.vim/pack/all/start/' . fnamemodify(a:pkg, ':t')))
        execute 'silent !git clone --depth 1 https://' . a:pkg . ' ~/.vim/pack/all/start/' . fnamemodify(a:pkg, ':t')
    endif
endfunction

call EnsurePackage('github.com/morhetz/gruvbox')

set background=dark
colorscheme gruvbox

set mouse=a
set number
set ruler
set cursorline
set shiftwidth=4
set expandtab
set t_ut=
