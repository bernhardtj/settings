# .aliases

# User specific environment
if ! [[ "$PATH" =~ $HOME/.local/bin:$HOME/bin: ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

_wrap_update_prompt_once() {
    local lockfile="$HOME/.cache/aliases/updater-blacklist"
    mkdir -p "$(dirname "$lockfile")"
    touch "$lockfile"
    if ! grep "$*" "$lockfile" >/dev/null; then
        eval "$*" | tee >(if ! grep "nstalled" >/dev/null; then
            printf '%s\n' "$*" >>"$lockfile"
        fi)
    fi
}

# _get_from_github: extract github releases tarballs over .local
# usage: _get_from_github <dev/app> <filename> <tar_flag> <success_cmd> [installer_cmd]
#        where VER completes to the version name.
# if installer_cmd is specified, it is eval'd with the tarball root as pwd.
_get_from_github() {
    URL="https://github.com/$1/releases"
    VERSION=$(curl -s "$URL/latest" | sed 's/.*tag\/\(.*\)".*/\1/g')
    printf "Install %s release %s? [yN] " "$1" "$VERSION" && read -r yesno
    if [[ "$yesno" =~ [Yy] ]]; then
        if [[ $5 ]]; then
            dest=$(mktemp -d)
            installer_cmd=${5//VER/${VERSION//v/}}
        else
            dest=$HOME/.local
            installer_cmd=
        fi
        set -e
        curl '-#L' "$URL/download/$VERSION/${2//VER/${VERSION//v/}}" | tar "x$3C" "$dest"
        bash -c "cd '$dest' && eval '$installer_cmd'"
        printf "Installed %s!\n" "$(eval "$4")"
    fi
}

alias kitty-update="_get_from_github kovidgoyal/kitty kitty-VER-x86_64.txz J 'kitty --version'"
alias pandoc-update="_get_from_github jgm/pandoc pandoc-VER-linux-amd64.tar.gz z 'pandoc --version'"
alias hub-update="_get_from_github github/hub hub-linux-amd64-VER.tgz z 'hub --version | tail -n1' 'prefix=$HOME/.local ./hub-linux-amd64-VER/install'"
alias gh-update="_get_from_github cli/cli gh_VER_linux_amd64.tar.gz z 'gh --version | head -n1' 'cp -r gh_VER_linux_amd64/{bin,share} $HOME/.local'"

arm-none-eabi-update() {
    URL=https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads
    LINK="$(curl -s $URL | grep -m 1 '64-bit.*Linux' | cut -d '"' -f2 | cut -d '?' -f1)"
    printf "Install %s? [yN] " "$(basename "${LINK/\.tar.*//}")" && read -r yesno
    if [[ "$yesno" =~ [Yy] ]]; then
        curl '-#L' "https://developer.arm.com$LINK" | tar xjC "$HOME/.local" --strip 1
        cat <<'EOF'
GCC is installed! Remember to do this to your CMakeLists_template.txt:
sed -i s,\ arm-none-eabi,\ $HOME/.local/bin/arm-none-eabi,g CMakeLists_template.txt
EOF
    fi
}

jetbrains-toolbox-update() {
    URL='https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release'
    prefix=$(mktemp -d)
    eval "$(
        python <<EOF
import json
resp = json.loads(r"""$(curl -s "$URL")""")['TBA'][0]
print(f"printf 'Install jetbrains-toolbox {resp['type']} {resp['date']}? [Y] '; read;")
print(f"curl '-#L' {resp['downloads']['linux']['link']} | tar xzC $prefix --strip 1;")
print("$prefix/jetbrains-toolbox;")
EOF
    )"
}

sudo () {
    if [[ $TERM == linux ]]; then
        pkttyagent -p $$ | pkexec sh -c "cd $(pwd) && $*; killall pkttyagent"
    else
        pkexec sh -c "cd $(pwd) && $*"
    fi
}

rpm-ostree-auto-updates() {
    sudo bash <<EOF
set -x
sed s/^#A/A/g\;s/none/stage/g /usr/etc/rpm-ostreed.conf >/etc/rpm-ostreed.conf
systemctl enable rpm-ostreed-automatic.timer
EOF
}

copr-enable() {
    release_ver=$(rpm -E %fedora)
    sudo bash -c "cd /etc/yum.repos.d && curl -LO https://copr.fedorainfracloud.org/coprs/$1/repo/fedora-$release_ver/${1//\//\-}-fedora-$release_ver.repo"
}

sync_toolbox_gui_apps() { toolbox run bash -c 'ls -1 /usr/share/applications | while read line; do cat /usr/share/applications/$line | sed "/TryExec/d; s/Exec=/Exec=toolbox run /g" > ~/.local/share/applications/$line; done && cp -r /usr/share/icons ~/.local/share/ && cp -r /usr/share/fonts ~/.local/share/'; }

toolbox-provision() {
    podman stop --all
    podman rm --all
    podman rmi --all
    echo 'y' | toolbox create
    toolbox run sudo curl -L -o /etc/yum.repos.d/miktex.repo https://miktex.org/download/fedora/30/miktex.repo
    toolbox run sudo sed -i "$ a gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-miktex" /etc/yum.repos.d/miktex.repo
    toolbox run sudo curl -L -o /etc/pki/rpm-gpg/RPM-GPG-KEY-miktex "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xD6BC243565B2087BC3F897C9277A7293F59E4889"
    toolbox run bash -c 'echo "export QT_QPA_PLATFORMTHEME=gtk2" | sudo  tee  /etc/profile.d/qtstyleplugins.sh'
    toolbox run bash -c 'sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm adapta-gtk-theme qt5-qtstyleplugins ghostscript miktex emacs atril zsh'
}

_math() { echo $(($1)); }
alias math='noglob _math'

dict() { curl -s "dict.org/${${*//-/}// /:}" | sed '/^2/d'; }

export EDITOR='emacs -nw'

alias :q=exit
alias q=exit

alias kitty-diff='kitty +kitten diff'
alias icat='kitty icat'

alias gnu='test "$TERM" = "linux" && curl https://www.gnu.org/graphics/agnuheadterm-tty.txt || curl https://www.gnu.org/graphics/agnuheadterm-xterm.txt'
alias fsf='echo "warranty" | bc | tail -n 5'
alias fom='curl -s https://llocds.ligo-la.caltech.edu/screencapture/FOM/FOM_RANGE.png | kitty icat'

alias quote="sed -i 's/^/\>/g'"
alias proc='ps a -u $(whoami)'

alias slack-dl='curl -L -H "Authorization: Bearer $(cat $HOME/.config/slack-cli/slack_token)"'

alias flathub-update='flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo'

pygmentize="[[ -f $HOME/.local/bin/pygmentize ]] || pip install --user --force-reinstall pygments >/dev/null && $HOME/.local/bin/pygmentize"
alias pcat="$pygmentize -f terminal256 -O style=native -g"
alias pless="LESSOPEN='|($pygmentize -f terminal256 -O style=native -g %s)' less"

if type -p hub >/dev/null; then
    eval "$(hub alias -s)"
else
    _wrap_update_prompt_once hub-update
fi

if [[ ! -f $HOME/.local/bin/kitty ]]; then
    _wrap_update_prompt_once kitty-update
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

see_term_colors() {
    printf "\e[30m K \e[31m R \e[32m G \e[33m Y \e[0m"
    printf "\e[34m B \e[35m M \e[36m C \e[37m W \e[0m"
    echo
    printf "\e[30;1m K \e[31;1m R \e[32;1m G \e[33;1m Y \e[0m"
    printf "\e[34;1m B \e[35;1m M \e[36;1m C \e[37;1m W \e[0m"
    echo
    printf "\e[40m K \e[41m R \e[42m G \e[43m Y \e[0m"
    printf "\e[44m B \e[45m M \e[46m C \e[47m W \e[0m"
    echo
    printf "\e[40;1m K \e[41;1m R \e[42;1m G \e[43;1m Y \e[0m"
    printf "\e[44;1m B \e[45;1m M \e[46;1m C \e[47;1m W \e[0m"
    echo
    printf "\e[1m BOLD \e[0m\e[4m Underline \e[0m\e[7m Reversed \e[0m"
    echo
}

settings-provision-remote () {
    ssh "$@" bash -c 'cd ~ && rm -rf settings && git clone https://github.com/bernhardtj/settings && settings/apply'
}