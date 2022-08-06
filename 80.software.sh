#!/usr/bin/env bash
# true
# software in the home folder

# _get_from_github: extract github releases tarballs over .local
# usage: _get_from_github <dev/app> <filename> <tar_flag> <success_cmd> [installer_cmd]
#        where VER completes to the version name.
# if installer_cmd is specified, it is eval'd with the tarball root as pwd.
_get_from_github() {
    echo 'Tried _get_from_github! This is broken now, and not implemented.' >&2
    exit 1
}

# _get_from_dnf: extract rpms over .local
# usage: _get_from_dnf <package_name>
_get_from_dnf() {
    URLS="$(curl '-#L' "https://mirrors.fedoraproject.org/metalink?repo=fedora-$(rpm -E %fedora)&arch=$(arch)" |
        sed -n '/>https/{s/^.*">\(http.*\)repodata.*$/\1/g;p}')"
    for url in $URLS; do
        pkg="$(curl '-#L' "$url/Packages/${1::1}" | grep "\"$1-" -m1 | sed 's/^.*href="\(.*rpm\)">.*$/\1/g')"
        echo Setting up $pkg...
        curl '-#L' "$url/Packages/${1::1}/$pkg" | rpm2cpio - | cpio -idum "./usr/*"
        cp -r ./usr/* "$HOME/.local"
        break
    done
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
