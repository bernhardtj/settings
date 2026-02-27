#!/bin/bash
# which firefox

URL=https://raw.githubusercontent.com/arkenfox/user.js/master/user.js

if [[ ! -e $HOME/.config/mozilla/firefox ]]; then
    firefox --headless >/dev/null 2>/dev/null &
    pid=$!
    sleep 0.3 && kill -9 $pid 2>/dev/null
fi

[[ ! -e "$HOME/.arkenfox" ]] && curl -sLo "$HOME/.arkenfox" "$URL"

for profile in "$HOME"/.config/mozilla/firefox/*.default-release; do
    cat "$HOME/.arkenfox" <(sed -n '/^user_pref/,$p' "${BASH_SOURCE[0]}") > "$profile/user.js"
    printf '{"chrome://browser/content/browser.xhtml":{"toolbar-menubar":{"autohide":"false"}}}' > "$profile/xulstore.json"
done
exit

# overrides
user_pref("browser.startup.homepage", "https://start.fedoraproject.org/");
user_pref("browser.startup.page", 1);
user_pref("browser.uiCustomization.state", '{"placements":{"nav-bar":["urlbar-container","search-container"]}}');
