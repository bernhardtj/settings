.local/bin/ssh
#!/bin/bash
case "$1" in
*'password: ')
    PASS="$(sed -n "s/^$1\(.*\)/\1/p" ~/.ssh/pass)"
    [[ $PASS ]] || read -rsp "$1" PASS
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
