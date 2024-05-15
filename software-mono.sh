#!/bin/bash

_software_recipes_dir="$HOME/settings/software"

_get_from_github() {
    URL="https://github.com/$1/releases"
    if [[ ! $VERSION ]]; then
        VERSION="$(curl -v "$URL/latest" 2>&1 | /bin/grep location | sed 's,^.*tag/,,g' | tr -d '\r\n')"
    fi
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

_get_from_dnf() {
    pushd "$(mktemp -d)" >/dev/null 2>&1
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
    popd >/dev/null 2>&1
}

_software_entrypoint() {
    if ! nm-online -qx; then
        echo 'settings/software: offline; doing nothing.' >&2
        return 1
    fi
    cd "$(mktemp -d)"
    recipe_install
    bash "$_software_recipes_dir/../99.permissions.sh"
    cd - >/dev/null
    if [[ "$*" ]]; then
        "$@"
    fi
}

shopt -s expand_aliases
# shellcheck disable=SC2154
alias _software_iterate_recipes_begin='
for recipe in "$_software_recipes_dir"/*.sh; do
    unset -f recipe_{bin,install}
    eval "$(cat "$recipe")"
    for link in $(recipe_bin); do
'
alias _software_iterate_recipes_end='done; done'

usage() {
    echo 'settings/software: usage error'
    exit "$@"
}

parse_args() {
    MODE=
    BIN=
    _flag_store_to=
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            usage 0
            ;;
        -s | --setup)
            MODE=setup
            ;;
        -i | --install)
            MODE=install
            _flag_store_to=BIN
            ;;
        *)
            if [[ $_flag_store_to ]]; then
                eval "$_flag_store_to=$1"
                _flag_store_to=
            else
                usage 1
            fi
            ;;
        esac
        shift
    done

    if [[ $_flag_store_to ]]; then
        usage 1
    fi

    if [[ ! $MODE ]]; then
        usage 1
    fi

}

check_softlink() {
    BIN="$(basename "$0")"
    CONTINUE_ARGS=
    case "$BIN" in
    software-mono.sh | \
        software-update)
        return 1
        ;;
    esac
    MODE=install
    CONTINUE_ARGS=("$BIN" "$@")
}

main() {

    if ! check_softlink "$@"; then
        parse_args "$@"
    fi

    case $MODE in
    setup)
        _software_iterate_recipes_begin
        # shellcheck disable=SC2154
        if [[ ! -e "$HOME/.local/bin/$link" ]]; then
            ln -sf "$HOME/.local/bin/"{software-update,"$link"}
        fi
        _software_iterate_recipes_end
        ;;
    install)
        _software_iterate_recipes_begin
        if [[ $link == "$BIN" ]]; then
            for b in $(recipe_bin); do rm -f "$HOME/.local/bin/$b"; done
            _software_entrypoint "${CONTINUE_ARGS[@]}"
            exit $?
        fi
        _software_iterate_recipes_end
        echo "settings/software: couldn't find a recipe for $BIN." >&2
        exit 1
        ;;
    esac

}

if [[ ! ${BASH_SOURCE[1]} ]]; then
    main "$@"
fi
