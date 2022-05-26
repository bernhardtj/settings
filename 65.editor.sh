#!/usr/bin/env bash
# true

mkdir -p "$HOME/.local/bin"

rm -f "$HOME/.local/bin/emacs"

if ! type emacs >/dev/null 2>/dev/null; then
    if type flatpak >/dev/null 2>/dev/null; then
        if flatpak list | grep org.gnu.emacs >/dev/null 2>/dev/null; then
            printf 'flatpak run --command=bash org.gnu.emacs -ic "/app/bin/emacs $*"' >"$HOME/.local/bin/emacs"
        fi
    fi
fi