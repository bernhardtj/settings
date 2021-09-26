#!/usr/bin/env bash
# test -n "$DISPLAY"
# see https://github.com/tonsky/FiraCode/wiki/Linux-instructions

fonts_dir="${HOME}/.local/share/fonts"
if [ ! -d "${fonts_dir}" ]; then
    echo "mkdir -p $fonts_dir"
    mkdir -p "${fonts_dir}"
else
    echo "Found fonts dir $fonts_dir"
fi

if [[ ! -f "$HOME/.local/share/fonts/ttf/FiraCode-Regular.ttf" ]]; then
    URL="https://github.com/tonsky/FiraCode/releases"
    version=$(curl -s "$URL/latest" | sed 's/.*tag\/\(.*\)".*/\1/g')
    curl -sLo /tmp/fira.zip $URL/download/${version}/Fira_Code_v${version}.zip
    unzip -oqd ${fonts_dir} /tmp/fira.zip
    echo "fc-cache -f" && fc-cache -f
fi
