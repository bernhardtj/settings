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
    dest=$(mktemp -d)
    installer_cmd=${5//VER/${VERSION//v/}}
  else
    dest=$HOME/.local
    installer_cmd=
  fi
  set -e
  curl '-#L' "$URL/download/$VERSION/${2//VER/${VERSION//v/}}" | tar "x$3C" "$dest"
  bash -c "cd '$dest' && eval '$installer_cmd'"
  printf "Installed %s!\n" "$(eval "$4")"
}

if [[ ! "${BASH_SOURCE[1]}" ]]; then
  for recipe in "$(dirname "${BASH_SOURCE[0]}")/software"/*.sh; do
    eval "$(cat "$recipe")"
    for link in $(recipe_bin); do
      if [[ ! -e "$HOME/.local/bin/$link" ]]; then
        printf '#!/bin/bash\n. %s && . %s && recipe_install && ${BASH_SOURCE[0]} "$@"; exit' "$(realpath "${BASH_SOURCE[0]}")" "$(realpath "$recipe")" >"$HOME/.local/bin/$link"
      fi
    done
  done
fi
