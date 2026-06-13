#!/bin/bash
# which firefox

URL=https://raw.githubusercontent.com/arkenfox/user.js/master/user.js

arkenfox_overrides() {
    cat <<'EOF'
user_pref("browser.startup.homepage", "https://start.fedoraproject.org/");
user_pref("browser.startup.page", 1);
user_pref("browser.uiCustomization.state", '{"placements":{"nav-bar":["urlbar-container","search-container"]}}');
EOF
}

if [[ ! -e "$HOME/.mozilla" && ! -e "$HOME/.config/mozilla" ]]; then
    firefox --headless >/dev/null 2>/dev/null &
    pid=$!
    sleep 0.3 && kill -9 $pid 2>/dev/null
fi

[[ ! -e "$HOME/.arkenfox" ]] && curl -sLo "$HOME/.arkenfox" "$URL"

firefox_roots=(
    "$HOME/.mozilla/firefox"
    "$HOME/.config/mozilla/firefox"
    "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox"
    "$HOME/.var/app/org.mozilla.firefox/.config/mozilla/firefox"
    "$HOME/.var/app/org.mozilla.firefox/config/mozilla/firefox"
)

profile_suffixes=(
    "*.default"
    "*.default-release"
    "*.default-esr"
)

profiles=()
shopt -s nullglob
for root in "${firefox_roots[@]}"; do
    for suffix in "${profile_suffixes[@]}"; do
        profiles+=("$root"/$suffix)
    done
done
shopt -u nullglob

if [[ ${#profiles[@]} -eq 0 ]]; then
    echo "70-arkenfox: no Firefox profiles found" >&2
    exit 0
fi

for profile in "${profiles[@]}"; do
    [[ -d $profile ]] || continue
    cat "$HOME/.arkenfox" <(arkenfox_overrides) >"$profile/user.js"
    printf '{"chrome://browser/content/browser.xhtml":{"toolbar-menubar":{"autohide":"false"}}}' >"$profile/xulstore.json"
done
