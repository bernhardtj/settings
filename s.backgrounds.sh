# .local/bin/wallpapers-update
#!/bin/bash
out="$HOME/.cache/wallpaper_browser.html"
results=https://apps.fedoraproject.org/nuancier/results

cat << EOF > "$HOME/.local/share/applications/wallpaper_browser.desktop"
[Desktop Entry]
Name=Fedora supplementary wallpapers
Comment=Browse the fedora-extras backgrounds
Exec=xdg-open "$out"
Icon=preferences-desktop-theme
Terminal=false
Type=Application
StartupNotify=true
Categories=GTK;Settings;DesktopSettings;
Keywords=mate-control-center;MATE;appearance;properties;desktop;customize;look;
X-Desktop-File-Install-Version=0.24
EOF

curl -sL $results/1 | sed '/\/head/q;' | sed '/shortcut/,/koji/d;' | sed 's/\/nuancier/https\:\/\/apps\.fedoraproject\.org\/nuancier/g' > "$out"
cat << EOF >> "$out"
<body id="results">
<div id="wrap">
<div id="innerwrap">
<div id="content">
EOF
i=0
until [[ "$result" == *"No election found"* ]]; do
i=$((i+1))
echo '<hr>' >> "$out"
result=$(curl -sL $results/$i)
echo "$result" | sed -n '/table/,/table/p' | sed -n '/a href/,/\/a\>/p;' | sed 's/\/nuancier/https\:\/\/apps\.fedoraproject\.org\/nuancier/g' >> "$out"
done
echo " </div> </div> </div> </body> </html>" >> "$out"
