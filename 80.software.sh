#!/usr/bin/env bash
# true
# software in the home folder

# _get_from_github: extract github releases tarballs over .local
# usage: _get_from_github <dev/app> <filename> <tar_flag> <success_cmd> [installer_cmd]
#        where VER completes to the version name.
# if installer_cmd is specified, it is eval'd with the tarball root as pwd.
_get_from_github() {
    URL="https://github.com/$1/releases"
    VERSION=$(curl -s "$URL/latest" | sed 's/.*tag\/\(.*\)".*/\1/g')
    if [[ $5 ]]; then
        dest=.
        installer_cmd=${5//VER/${VERSION//v/}}
    else
        dest=$HOME/.local
        installer_cmd=
    fi
    set -e
    curl '-#L' "$URL/download/$VERSION/${2//VER/${VERSION//v/}}" | tar -x -$3 -C "$dest"
    bash -c "cd '$dest' && eval '$installer_cmd'"
    printf "Installed %s!\n" "$(eval "$4")" >&2
}

try() {
    declare -f "$1" >/dev/null && "$@"
}

# usage: _software_visual begin; ... ; _software_visual end;
_software_visual() {
    for desktop in $(try recipe_visual_bin); do
        if [[ $1 == end ]] || [[ ! -e "$HOME/.local/share/applications/$desktop" ]]; then
            try "recipe_visual_$1" "$desktop"
        fi
    done
}

_software_entrypoint() {
    cd "$(mktemp -d)"
    if [[ $1 == recipevisual ]]; then
        COMMAND=recipe_visual_install
        shift
    else
        COMMAND=recipe_install
    fi
    $COMMAND
    cd - >/dev/null
    ${BASH_SOURCE[1]} "$@"
}

if [[ ! ${BASH_SOURCE[1]} ]]; then
    set -e
    cd "$(mktemp -d)"
    for recipe in "$(dirname "${BASH_SOURCE[0]}")/software"/*.sh; do
        unset -f recipe_{bin,install,visual_{bin,install,begin,end}}
        eval "$(cat "$recipe")"
        for link in $(recipe_bin); do
            if [[ ! -e "$HOME/.local/bin/$link" ]]; then
                cat <<EOF >"$HOME/.local/bin/$link"
#!/bin/bash
source "$(realpath "${BASH_SOURCE[0]}")"
source "$(realpath "$recipe")"
_software_entrypoint "\$@" && exit
EOF
            fi
        done
        _software_visual begin
    done
fi
