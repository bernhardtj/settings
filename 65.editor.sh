#!/usr/bin/env bash
# true

mkdir -p "$HOME/.local/bin"

rm -f "$HOME/.local/bin/"{emacs,vim}

if ! type emacs >/dev/null 2>/dev/null; then
    if type flatpak >/dev/null 2>/dev/null; then
        if flatpak list | grep org.gnu.emacs >/dev/null 2>/dev/null; then
            printf 'flatpak run org.gnu.emacs "$@"' >"$HOME/.local/bin/emacs"
        fi
    fi
fi

if ! type vim >/dev/null 2>/dev/null; then
    if type flatpak >/dev/null 2>/dev/null; then
        if flatpak list | grep org.vim.Vim >/dev/null 2>/dev/null; then
            printf 'flatpak run org.vim.Vim "$@"' >"$HOME/.local/bin/vim"
        fi
    fi
fi
