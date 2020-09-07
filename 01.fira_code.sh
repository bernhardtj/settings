#!/usr/bin/env bash
# true
# see https://github.com/tonsky/FiraCode/wiki/Linux-instructions

fonts_dir="${HOME}/.local/share/fonts"
if [ ! -d "${fonts_dir}" ]; then
    echo "mkdir -p $fonts_dir"
    mkdir -p "${fonts_dir}"
else
    echo "Found fonts dir $fonts_dir"
fi

for type in Bold Light Medium Regular Retina; do
    file_path="${HOME}/.local/share/fonts/FiraCode-${type}.ttf"
    file_url="https://github.com/tonsky/FiraCode/blob/master/distr/ttf/FiraCode-${type}.ttf?raw=true"
    if [ ! -e "${file_path}" ]; then
        echo "wget -O $file_path $file_url"
        curl -sLo "${file_path}" "${file_url}"
    else
        echo "Found existing file $file_path"
    fi
done

file_path="${HOME}/.local/share/fonts/FiraCode-Regular-Symbol.otf"
file_url="https://github.com/tonsky/FiraCode/files/412440/FiraCode-Regular-Symbol.zip"
if [ ! -e "${file_path}" ]; then
    echo "wget -O $file_path $file_url"
    curl -sL "${file_url}" | gunzip - >"${file_path}"
else
    echo "Found existing file $file_path"
fi

echo "fc-cache -f"
fc-cache -f
