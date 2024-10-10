#!/usr/bin/env bash
# true

settings_folder="$(dirname "${BASH_SOURCE[0]}")"

# delete empty directories and broken symlinks
find "$HOME" -mount -maxdepth 1 -type d -empty -delete 2>/dev/null
find "$HOME" -mount -xtype l -delete 2>/dev/null

# run shfmt on scripts
shfmt -s -i 4 -w "$settings_folder" 2>/dev/null

# set permissions
find "$settings_folder" -mount -type f -exec chmod 644 {} \; 2>/dev/null
find "$settings_folder" -mount -type d -exec chmod 755 {} \; 2>/dev/null
find "$HOME/.local/bin" -mount -maxdepth 1 -exec chmod 755 {} \; 2>/dev/null
find "$HOME/.ssh" -mount -type f -exec chmod 600 {} \; 2>/dev/null

chmod 755 "$settings_folder/apply"
