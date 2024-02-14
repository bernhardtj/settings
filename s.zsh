# .zshrc

# Source global definitions
if [ -f /etc/zshrc ]; then
    . /etc/zshrc
fi

ANTIGEN=$HOME/.antigen.zsh
if ! [[ -e $ANTIGEN ]]; then
    echo 'Installing Antigen...'
    curl -sL git.io/antigen -o "$ANTIGEN"
fi
# shellcheck disable=SC1090
source "$ANTIGEN"
antigen use oh-my-zsh
antigen bundle git
antigen bundle git-extras
antigen bundle github
antigen bundle ripgrep
antigen bundle pip
#antigen theme robbyrussell
antigen apply

host_info='$([[ $SSH_CONNECTION ]] && printf "%%m" || printf "➜ ")'

PROMPT="%(?:%{$fg_bold[green]%}$host_info:%{$fg_bold[red]%}$host_info) %{$fg[cyan]%}%c%{$reset_color%}"
PROMPT+=' $(git_prompt_info)'

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"

if test -n "$KITTY_INSTALLATION_DIR"; then
    export KITTY_SHELL_INTEGRATION="enabled"
    autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
    kitty-integration
    unfunction kitty-integration
fi

source "$HOME/.aliases"
