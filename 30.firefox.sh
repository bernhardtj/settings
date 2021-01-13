#!/bin/bash
# type -p firefox
rm -rf "$HOME"/{.,.cache/}mozilla
firefox --headless >/dev/null 2>/dev/null & sleep 0.3 && killall firefox
cd "$HOME"/.mozilla/firefox/*.default-release && curl -sLO https://raw.githubusercontent.com/arkenfox/user.js/master/updater.sh && bash ./updater.sh -s
