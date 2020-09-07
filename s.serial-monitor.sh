# .local/bin/serial-monitor
#!/bin/bash

usage() {
    cat <<EOF
Usage:
  femtocom <serial-port> [ <speed> [ <stty-options> ... ] ]
  Example: $0 /dev/ttyS0 9600
  See man stty or stty --help for more options
  Press Ctrl+Q to quit
EOF
    exit
}

serial_mon() {
    set -e
    restore_term="stty $(stty -g)"
    trap 'set +e; [[ "$readerPid" ]] && kill "$readerPid"; $restore_term' EXIT
    stty -F "$SERIAL_PORT" raw -echo "$@"
    stty raw -echo isig intr ^Q quit undef susp undef
    cat "$SERIAL_PORT" &
    readerPid=$!
    cat >"$SERIAL_PORT"
}

[[ $# -lt 1 ]] && usage

case $1 in
*help* | -h) usage ;;
*)
    SERIAL_PORT="$1"
    shift
    serial_mon "$@"
    ;;
esac
