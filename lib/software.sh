#!/usr/bin/env bash

_get_from_mason() {
    nvim --headless -c 'Mason' -c "MasonInstall --force $1" -c 'quitall'
    echo
}

_get_dl_link_from_github() {
    local repo="$1"
    local asset="$2"
    local url="https://github.com/$repo/releases"
    if [[ ! ${VERSION:-} ]]; then
        VERSION="$(curl -v "$url/latest" 2>&1 | /bin/grep location | sed 's,^.*tag/,,g' | tr -d '\r\n')"
    fi
    printf "Found ver. %s...\n" "$VERSION" >&2
    echo "$url/download/$VERSION/${asset//VER/${VERSION//v/}}"
}

_get_from_github() {
    set -e
    local repo="$1"
    local asset="$2"
    local tar_flags="$3"
    local check_cmd="$4"
    local dest
    local installer_cmd
    if [[ ${5:-} ]]; then
        dest=.
        installer_cmd=${5//VER/${VERSION//v/}}
    else
        dest=$HOME/.local
        installer_cmd=
    fi
    curl '-#L' "$(_get_dl_link_from_github "$repo" "$asset")" | tar -x "-$tar_flags" -C "$dest"
    bash -c "cd '$dest' && eval '$installer_cmd'"
    printf "Installed %s!\n" "$(eval "$check_cmd")" >&2
    set +e
}

_get_from_dnf() {
    pushd "$(mktemp -d)" >/dev/null 2>&1
    echo 'Fetching mirrorlist...'
    local urls
    urls="$(curl '-sL' "https://mirrors.fedoraproject.org/metalink?repo=fedora-$(rpm -E %fedora)&arch=$(arch)" |
        sed -n '/>https/{s/^.*">\(http.*\)repodata.*$/\1/g;p}')"
    for url in $urls; do
        echo "Querying $url for $1..."
        local pkg
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
