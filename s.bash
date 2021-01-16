# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

shopt -s checkwinsize histappend autocd

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# the possible locations for this infernal script
while read -r line; do [[ -f $line ]] && source "$line"; done <<EOF
/etc/bash_completion.d/git-prompt
/usr/share/git/completion/git-prompt.sh
/usr/share/git-core/contrib/completion/git-prompt.sh
EOF

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUNTRACKEDFILES=1
GIT_PS1_SHOWSTASHSTATE=1
GIT_PS1_SHOWUPSTREAM='auto'
GIT_PS1_STATESEPARATOR=''
GIT_PS1_DESCRIBE_STYLE='default'

if [[ $TERM == *color* ]]; then
    GIT_PS1_SHOWCOLORHINTS=1
    _c_code() {
        printf '\033[%sm' "$(printf ';%s' "$@")"
    }
else
    _c_code() {
        :
    }
fi

PROMPT_FMT='$((($?)) && _c_code 1 31 || _c_code 1 32)$([[ $SSH_CONNECTION ]] && printf "\h" || printf "➜")  $(_c_code 1 36)\W$(_c_code 0)'

if declare -f __git_ps1 >/dev/null; then
    PROMPT_COMMAND='__git_ps1 "$PROMPT_FMT" " "'
else
    PS1="$PROMPT_FMT "
fi

if [[ -o emacs || -o vi ]]; then
    bind 'TAB:menu-complete'
    bind 'set show-all-if-ambiguous on'
    bind 'set completion-ignore-case on'
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
    bind '"\eh": "\C-a\eb\ed\C-y\e#man \C-y\C-m\C-p\C-p\C-a\C-d\C-e"'
fi

source "$HOME/.aliases"
