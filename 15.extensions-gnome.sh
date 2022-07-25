#!/usr/bin/env bash
# test "$XDG_CURRENT_DESKTOP" = GNOME

add() {
    PREFIX="$HOME/.local/share/gnome-shell/extensions/settings-$1@localhost"
    if [[ $2 == - || ! -e "$PREFIX/extension.js" ]]; then
        rm -rf "$PREFIX"
        XDG_DATA_DIRS='' gnome-extensions create \
            --name="Settings $1 for GNOME" \
            --description='GNOME Shell javascript tweaks, per Settings' \
            --uuid="settings-$1@localhost" \
            2>/dev/null
    fi
    if [[ $2 != - && ! -e "$PREFIX/extension.js" ]]; then
        curl -sLo "$PREFIX/extension.js" "$2"
    fi
    if [[ $3 != - ]]; then
        $3
    fi
}

main_schema() {
    mkdir -p "$PREFIX/schemas"
    cat <<'EOF' >"$PREFIX/schemas/org.gnome.shell.extensions.settings.gschema.xml"
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
<schema id="org.gnome.shell.extensions.settings" path="/org/gnome/shell/extensions/settings/">
<key type="as" name="flop-left"><default><![CDATA[['<Super>b']]]></default></key>
<key type="as" name="flop-right"><default><![CDATA[['<Super>f']]]></default></key>
</schema>
</schemalist>
EOF
    glib-compile-schemas "$PREFIX/schemas"
}

add main - main_schema
add tray https://raw.githubusercontent.com/zhangkaizhao/gnome-shell-extension-tray-icons/master/extension.js
add remmina https://raw.githubusercontent.com/alexmurray/remmina-search-provider/master/extension.js

gsettings reset org.gnome.shell disable-user-extensions
