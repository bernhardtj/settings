.local/bin/ssh
#!/bin/bash
case "$1" in
*'password: ')
    PASS="$(sed -n "s/^$1\(.*\)/\1/p" ~/.ssh/pass 2>/dev/null)"
    if [[ ! $PASS ]]; then
        read -rsp "$1" PASS
        printf 'Save password? [yN]: ' >&2 && read -r yesno
        [[ $yesno =~ [Yy] ]] && echo "$1$PASS" >>~/.ssh/pass
    fi
    echo $PASS
    ;;
*'[fingerprint])? ')
    echo yes
    ;;
*)
    export SSH_ASKPASS_REQUIRE=force
    export SSH_ASKPASS="$(realpath "${BASH_SOURCE[0]}")"
    setsid /bin/ssh "$@"
    ;;
esac
