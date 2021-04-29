.local/bin/arkenfox
#!/bin/bash
! type -p firefox >/dev/null && echo 'Doing Nothing.' && exit 1
case "$1" in
on)
    [[ "$(find "$HOME"/.mozilla/firefox/ -maxdepth 2 -name updater.sh)" ]] && exit
    [[ -e $HOME/.mozilla ]] && mv $HOME/.mozilla{,.bak}
    [[ -e $HOME/.mozilla.afox ]] && mv $HOME/.mozilla{.afox,} || (
        firefox --headless >/dev/null 2>/dev/null &
        sleep 0.3 && killall firefox
    )
    cd "$HOME"/.mozilla/firefox/*.default-release && curl -sLO https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh && bash ./updater.sh -s
    ;;
off)
    [[ "$(find "$HOME"/.mozilla/firefox/ -maxdepth 2 -name updater.sh)" ]] || exit
    mv $HOME/.mozilla{,.afox}
    [[ -e $HOME/.mozilla.bak ]] && mv $HOME/.mozilla{.bak,}
    ;;
*)
    echo 'arkenfox - turn on and off arkenfox mode
usage:
    arkenfox on
    arkenfox off'
    ;;
esac
