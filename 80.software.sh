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

_software_entrypoint() {
    cd "$(mktemp -d)"
    recipe_install
    bash "$(dirname "${BASH_SOURCE[0]}")/99.permissions.sh"
    cd - >/dev/null
    "$@"
}

_software_recipes_dir="$(dirname "${BASH_SOURCE[0]}")/software"
shopt -s expand_aliases
alias _software_iterate_recipes_begin='
for recipe in "$_software_recipes_dir"/*.sh; do
    unset -f recipe_{bin,install}
    eval "$(cat "$recipe")"
    for link in $(recipe_bin); do
'
alias _software_iterate_recipes_end='done; done'

if [[ ! ${BASH_SOURCE[1]} ]]; then
    _software_iterate_recipes_begin
    if [[ ! -e "$HOME/.local/bin/$link" ]]; then
        ln -sf "$HOME/.local/bin/"{software-update,"$link"}
    fi
    _software_iterate_recipes_end
fi
