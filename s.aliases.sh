# .aliases

# User specific environment
if ! [[ $PATH =~ $HOME/.local/bin:$HOME/bin: ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

#conda
[[ -f "$HOME/anaconda3/etc/profile.d/conda.sh" ]] && source "$HOME/anaconda3/etc/profile.d/conda.sh"

#rust
[[ -d "$HOME/.cargo" ]] && source "$HOME/.cargo/env"

#motd
[[ -f "$HOME/.motd" ]] && cat "$HOME/.motd"
(motd-update >~/.motd &)

export EDITOR=vi

alias :q=exit
alias q=exit

alias vi=nvim

alias rpt=rpm-ostree

alias kitty-diff='kitty +kitten diff'
alias icat='kitty icat'
alias grep='kitty +kitten hyperlinked_grep'
alias ssh='kitty +kitten ssh'
alias kclip='kitty +kitten clipboard'

alias gnu='test "$TERM" = "linux" && curl https://www.gnu.org/graphics/agnuheadterm-tty.txt || curl https://www.gnu.org/graphics/agnuheadterm-xterm.txt'
alias fsf='echo "warranty" | bc | tail -n 5'
alias fom='curl -s https://llocds.ligo-la.caltech.edu/screencapture/FOM/FOM_RANGE.png | kitty icat'

alias quote="sed -i 's/^/\>/g'"
alias proc='ps a -u $(whoami)'

alias slack-dl='curl -L -H "Authorization: Bearer $(cat $HOME/.config/slack-cli/slack_token)"'

alias pdfcat='gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=-'

alias _quiltp='test -d patches || {echo "not a quilt tree; doing nothing."; exit 1}'
alias _quilt_series_refresh='_quiltp && mkdir -p .pc && ls patches | sort > .pc/series'
alias _quilt_push_a='_quilt_series_refresh && git apply $(find patches -type f | sort)'
alias _quilt_pop_a='_quilt_series_refresh && git apply -R $(find patches -type f | sort -r)'

alias lidswitch-inhibit='systemd-inhibit --what=handle-lid-switch bash -c "echo press ^D to stop inhibiting lid switch; cat"'

dict() { zsh -c 'curl -s "dict.org/${${*//-/}// /:}"' "$@" | sed '/^2/d'; }

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto --hyperlink=auto'
fi

cdd() { cd -"$(d | /bin/grep "$1" | cut -d$'\t' -f1)"; }

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

sync_toolbox_gui_apps() {
    toolbox run bash -c "{ $(declare -f sync_toolbox_gui_apps | tail -n+4)"
    return
    while read -r line; do
        sed "/TryExec/d; s/Exec=/Exec=toolbox run /g" <"/usr/share/applications/$line" >"$HOME/.local/share/applications/$line"
    done < <(ls -1 /usr/share/applications)
    cp -r /usr/share/icons ~/.local/share/
    cp -r /usr/share/fonts ~/.local/share/
}

see_term_colors() {
    printf "\e[30m K \e[31m R \e[32m G \e[33m Y \e[0m"
    printf "\e[34m B \e[35m M \e[36m C \e[37m W \e[0m\n"
    printf "\e[30;1m K \e[31;1m R \e[32;1m G \e[33;1m Y \e[0m"
    printf "\e[34;1m B \e[35;1m M \e[36;1m C \e[37;1m W \e[0m\n"
    printf "\e[40m K \e[41m R \e[42m G \e[43m Y \e[0m"
    printf "\e[44m B \e[45m M \e[46m C \e[47m W \e[0m\n"
    printf "\e[40;1m K \e[41;1m R \e[42;1m G \e[43;1m Y \e[0m"
    printf "\e[44;1m B \e[45;1m M \e[46;1m C \e[47;1m W \e[0m\n"
    printf "\e[1m BOLD \e[0m\e[4m Underline \e[0m\e[7m Reversed \e[0m\n"
}

settings_git_refresh() {
    pushd "$(mktemp -d)" >/dev/null 2>/dev/null
    gh repo clone bernhardtj/settings -- --single-branch
    rm -rf ~/settings/.git
    mv settings/.git ~/settings
    popd >/dev/null 2>/dev/null
}

rpt-versionjump() {
    [[ ! $1 ]] && echo 'please pass version number' && return
    killall -9 gnome-software
    rpm-ostree cancel
    rpm-ostree update --uninstall rpmfusion-free-release --uninstall rpmfusion-nonfree-release --install rpmfusion-free-release --install rpmfusion-nonfree-release
    rpm-ostree rebase "fedora:fedora/$1/x86_64/silverblue"
}

repo() {
    [[ -f .repo/repo/repo ]] && install -Dm755 .repo/repo/repo ~/.local/bin/repo
    ~/.local/bin/repo "$@"
}

### Graveyard ###

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

#alias ffmpeg='flatpak run --command=ffmpeg --filesystem=home org.videolan.VLC'

#_math() { echo $(($1)); }
#alias math='noglob _math'

#sudo () {
#    if [[ 1 ]]; then
#        /bin/sudo "$@"
#    elif [[ $TERM == linux ]]; then
#        pkttyagent -p $$ | pkexec sh -c "cd $(pwd) && $*; killall pkttyagent"
#    else
#        pkexec sh -c "cd $(pwd) && $*"
#    fi
#}
#
#toolbox-provision() {
#    podman stop --all
#    podman rm --all
#    podman rmi --all
#    echo 'y' | toolbox create
#    toolbox run sudo curl -L -o /etc/yum.repos.d/miktex.repo https://miktex.org/download/fedora/30/miktex.repo
#    toolbox run sudo sed -i "$ a gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-miktex" /etc/yum.repos.d/miktex.repo
#    toolbox run sudo curl -L -o /etc/pki/rpm-gpg/RPM-GPG-KEY-miktex "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD6BC243565B2087BC3F897C9277A7293F59E4889"
#    toolbox run bash -c 'echo "export QT_QPA_PLATFORMTHEME=gtk2" | sudo  tee  /etc/profile.d/qtstyleplugins.sh'
#    toolbox run bash -c 'sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm adapta-gtk-theme qt5-qtstyleplugins ghostscript miktex emacs atril zsh'
#}

#settings-provision-remote() {
#    ssh "$@" bash -c 'cd ~ && rm -rf settings && git clone https://github.com/bernhardtj/settings && settings/apply'
#}
#
#backgrounds-update() {
#    mkdir -p $HOME/{.local/share/,.cache/gnome-control-center/}backgrounds
#    podman run --rm -it -v $HOME/.local/share/backgrounds:/mnt --security-opt=label=disable fedora bash <<'EOF'
#set -e
#dnf install -y *backgrounds* findutils
#find /usr/share/backgrounds -type f -exec sh -c \
#'install -Dvm644 {} /mnt/$(md5sum {} | cut -d \  -f1)_$(basename {})' \;
#rm -f /mnt/*.xml
#exit
#EOF
#}
