#!/usr/bin/env bash
# true

if [[ ! -e "$HOME"/.local/share/fonts/arial.ttf ]]; then
    git clone https://github.com/bernhardtj/settings --single-branch --depth 1 -b blobs /tmp/blobs
    cat /tmp/blobs/01.fonts.tar.xz.* | tar xvJC "$HOME"
fi
