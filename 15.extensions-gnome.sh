#!/usr/bin/env bash
# test "$XDG_CURRENT_DESKTOP" = GNOME

PREFIX=~/.local/share/gnome-shell/extensions/settings@localhost

rm -rf $PREFIX
XDG_DATA_DIRS='' gnome-extensions create \
    --name='Settings for GNOME' \
    --description='GNOME Shell javascript tweaks, per Settings' \
    --uuid="settings@localhost" \
    2>/dev/null

mkdir -p $PREFIX/schemas
cat <<'EOF' >$PREFIX/schemas/org.gnome.shell.extensions.settings.gschema.xml
<?xml version="1.0" encoding="UTF-8"?>
<schemalist>
<schema id="org.gnome.shell.extensions.settings" path="/org/gnome/shell/extensions/settings/">
<key type="as" name="flop-left"><default><![CDATA[['<Super>b']]]></default></key>
<key type="as" name="flop-right"><default><![CDATA[['<Super>f']]]></default></key>
</schema>
</schemalist>
EOF
glib-compile-schemas $PREFIX/schemas

gsettings reset org.gnome.shell disable-user-extensions
