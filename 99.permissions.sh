#!/usr/bin/env bash
# true
shfmt -s -i 4 -w "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null
find "$(dirname "${BASH_SOURCE[0]}")" -type f -exec chmod 644 {} \;
find "$(dirname "${BASH_SOURCE[0]}")" -type d -exec chmod 755 {} \;
chmod 755 "$HOME"/.local/bin/* "$(dirname "${BASH_SOURCE[0]}")/apply"
chmod 600 ~/.ssh/*
find "$HOME" -maxdepth 1 -type d -empty -exec rmdir {} \;
