.local/bin/motd-update
#!/bin/bash

d="$(date -d "$(rpm-ostree status | sed -n '/Version/{s/^.*(\(.*\))$/\1/gp;q}')" +%s)"
ago="$(("$(date +%s)" - d))"

if [[ "$(("$ago" / 86400))" -gt 14 ]]; then
    printf "Notice: stale base image @%s\n" "$(date +%D -d "@$d")"
fi
