.local/bin/motd-update
#!/bin/bash

d30=2592000

d=$(date -d "$(rpm-ostree status | sed -n '/Version/{s/^.*(\(.*\))$/\1/gp;q}')" +%s)

if [[ $((d + d30)) -lt $(date +%s) ]]; then
    printf "Notice: stale base image @%s\n" "$(date +%D -d "@$d")"
fi
