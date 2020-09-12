# .bash_profile

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

PREEXEC=$HOME/.bash-preexec.sh
if ! [[ -e "$PREEXEC" ]]; then
    echo 'Installing bash-preexec...'
    curl -s https://raw.githubusercontent.com/rcaloras/bash-preexec/master/bash-preexec.sh -o "$PREEXEC"
fi
source "$PREEXEC"

shopt -s checkwinsize histappend autocd

if [[ "$TERM" = *color* ]]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi

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

# history search for command being typed by pressing arrowkeys
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
#press alt-h for some help after a command is typed out
bind '"\eh": "\C-a\eb\ed\C-y\e#man \C-y\C-m\C-p\C-p\C-a\C-d\C-e"'

# the possible locations for this infernal script (Note: requires bash_preexec)
while read -r line; do [[ -f $line ]] && source "$line"; done << EOF
/etc/bash_completion.d/git-prompt
/usr/share/git/completion/git-prompt.sh
/usr/share/git-core/contrib/completion/git-prompt.sh
EOF

if declare -f __git_ps1 > /dev/null; then
GIT_PS1_SHOWDIRTYSTATE=true
GIT_PS1_SHOWUNTRACKEDFILES=true
GIT_PS1_SHOWSTASHSTATE=true
GIT_PS1_SHOWUPSTREAM="auto verbose name"
GIT_PS1_DESCRIBE_STYLE="default"
GIT_PS1_SHOWCOLORHINTS=true
precmd_git () { PS1=${PS1%\\*}; __git_ps1 "${PS1%⎇*}" "\\\$ " "⎇\[\033[01;40m\] %s"; }
precmd_functions+=(precmd_git)
fi

source "$HOME/.aliases"
