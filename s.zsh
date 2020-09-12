# .zshrc

# Source global definitions
if [ -f /etc/zshrc ]; then
    . /etc/zshrc
fi

ANTIGEN=$HOME/.antigen.zsh
if ! [[ -e "$ANTIGEN" ]]; then
    echo 'Installing Antigen...'
    curl -sL git.io/antigen -o "$ANTIGEN"
fi
source "$ANTIGEN"
antigen use oh-my-zsh
antigen bundle git git-extras
antigen theme robbyrussell
antigen apply

source "$HOME/.aliases"