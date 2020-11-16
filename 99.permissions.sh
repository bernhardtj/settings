#!/usr/bin/env bash
# true
find $(dirname ${BASH_SOURCE[0]}) -type f -exec chmod 644 {} \;
find $(dirname ${BASH_SOURCE[0]}) -type d -exec chmod 755 {} \;
chmod 755 "$HOME"/.local/bin/* $(dirname ${BASH_SOURCE[0]})/apply
chmod 600 ~/.ssh/*

