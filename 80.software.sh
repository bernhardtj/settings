#!/usr/bin/env bash
# true
# software in the home folder

# _get_from_github: extract github releases tarballs over .local
# usage: _get_from_github <dev/app> <filename> <tar_flag> <success_cmd> [installer_cmd]
#        where VER completes to the version name.
# if installer_cmd is specified, it is eval'd with the tarball root as pwd.
#_get_from_github() {
#    echo 'Tried _get_from_github! This is broken now, and not implemented.' >&2
#    exit 1
#}
# NB endpoint $URL/releases/expanded_assets/VER could be useful for autogenerating link schema
_get_from_github() {
    URL="https://github.com/$1/releases"
    VERSION="$(curl -v "$URL/latest" 2>&1 | /bin/grep location | sed 's,^.*tag/,,g' | tr -d '\r\n')"
    printf "Found ver. $VERSION...\n"
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

# _get_from_dnf: extract rpms over .local
# usage: _get_from_dnf <package_name>
_get_from_dnf() {
    pushd $(mktemp -d) 2>&1 >/dev/null
    echo 'Fetching mirrorlist...'
    URLS="$(curl '-sL' "https://mirrors.fedoraproject.org/metalink?repo=fedora-$(rpm -E %fedora)&arch=$(arch)" |
        sed -n '/>https/{s/^.*">\(http.*\)repodata.*$/\1/g;p}')"
    for url in $URLS; do
        echo "Querying $url for $1..."
        pkg="$(curl '-sL' "$url/Packages/${1::1}" | grep "\"$1-" -m1 | sed 's/^.*href="\(.*rpm\)">.*$/\1/g')"
        echo "Downloading $pkg..."
        if ! curl '-#L' -o "$pkg" "$url/Packages/${1::1}/$pkg"; then
            echo 'Download failed!'
            break
        fi
        printf 'Extracting package: '
        rpm2cpio "$pkg" | cpio -idum "./usr/*"
        echo "Performing installation..."
        cp -r ./usr/* "$HOME/.local"
        break
    done
    popd 2>&1 >/dev/null
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
