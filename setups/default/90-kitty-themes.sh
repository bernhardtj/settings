#!/bin/bash
# command -v kitten >/dev/null
set -euo pipefail

config_dir="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}"
mkdir -p "$config_dir"

install_theme() {
    local theme_name="$1"
    local output_name="$2"
    local temporary

    temporary="$(mktemp "$config_dir/.${output_name}.XXXXXX")"
    trap 'rm -f "$temporary"' RETURN
    kitten themes --reload-in=none --dump-theme "$theme_name" >"$temporary"
    if ! grep -q '^wayland_titlebar_color ' "$temporary"; then
        printf '\nwayland_titlebar_color background\n' >>"$temporary"
    fi
    mv -f "$temporary" "$config_dir/$output_name"
    trap - RETURN
}

# Theme names can refer to kitty's bundled themes or files in ~/.config/kitty/themes.
# These are the same files written by the interactive picker's light/dark actions.
install_theme 'GNOME Console Light' light-theme.auto.conf
install_theme 'GNOME Console Dark' dark-theme.auto.conf

# GNOME reports its normal (non-dark) style as no-preference. Keep that mode
# pointed at the light selection so changing the light theme updates both.
ln -sfnT light-theme.auto.conf "$config_dir/no-preference-theme.auto.conf"
