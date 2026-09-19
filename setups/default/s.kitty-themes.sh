.local/bin/kitty-themes
#!/usr/bin/env bash
set -uo pipefail

config_dir="${KITTY_CONFIG_DIRECTORY:-${XDG_CONFIG_HOME:-$HOME/.config}/kitty}"

status=0
kitten themes "$@" || status=$?

preserve_titlebar_color() {
    local path="$1"
    local target

    [[ -e $path ]] || return 0
    target="$(readlink -f "$path")"
    if grep -Eq '^[[:space:]#]*wayland_titlebar_color[[:space:]]' "$target"; then
        sed -i -E \
            's/^[[:space:]#]*wayland_titlebar_color[[:space:]].*$/wayland_titlebar_color background/' \
            "$target"
    else
        printf '\nwayland_titlebar_color background\n' >>"$target"
    fi
}

for name in \
    kitty.conf \
    current-theme.conf \
    light-theme.auto.conf \
    dark-theme.auto.conf \
    no-preference-theme.auto.conf; do
    preserve_titlebar_color "$config_dir/$name"
done

# The picker has already reloaded kitty, so update the live value after fixing
# its saved files. Outside kitty there is no live instance to update.
if [[ -n ${KITTY_PID:-} ]]; then
    kitten @ set-colors --all --configured \
        wayland_titlebar_color=background >/dev/null 2>&1 || true
fi

exit "$status"
