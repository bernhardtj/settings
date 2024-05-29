#!/usr/bin/env bash
# usage
# git rebase -i
# :%!bash stat.sh

while read -r line; do
    echo "$line"
    eval "$(sed -n '/^pick/{s/pick \([a-f0-9]*\) .*/git show --stat \1 /gp}' <<< "$line")" | sed -n '/|/,${s/^/# /p}'
    echo
done