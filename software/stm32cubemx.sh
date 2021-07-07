PERMALINK=https://www.st.com/content/ccc/resource/technical/software/sw_development_suite/group0/66/75/ec/d9/83/51/4d/d0/stm32cubemx-lin_v6-2-1/files/stm32cubemx-lin_v6-2-1.zip/jcr:content/translations/en.stm32cubemx-lin_v6-2-1.zip

recipe_bin() {
    echo STM32CubeMX
}

recipe_install() {
    curl '-#LO' $PERMALINK
    cat <<EOF >auto-install.xml
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<AutomatedInstallation langpack="eng">
    <com.st.microxplorer.install.MXHTMLHelloPanel id="readme"/>
    <com.st.microxplorer.install.MXLicensePanel id="licence.panel"/>
    <com.st.microxplorer.install.MXAnalyticsPanel id="analytics.panel"/>
    <com.st.microxplorer.install.MXTargetPanel id="target.panel">
        <installpath>$HOME/STM32Cube</installpath>
    </com.st.microxplorer.install.MXTargetPanel>
    <com.st.microxplorer.install.MXShortcutPanel id="shortcut.panel"/>
    <com.st.microxplorer.install.MXInstallPanel id="install.panel"/>
    <com.st.microxplorer.install.MXFinishPanel id="finish.panel"/>
</AutomatedInstallation>
EOF
    unzip *.zip
    ./Setup* auto-install.xml
    ln -sf $HOME/STM32Cube/STM32CubeMX $HOME/.local/bin/STM32CubeMX
    cat <<EOF >"$HOME/.local/share/applications/stm32cubemx.desktop"
[Desktop Entry]
Name=STM32CubeMX
Icon=STM32CubeMX
Comment=STM32CubeMX
Exec=$HOME/STM32Cube/STM32CubeMX
Version=1.0
Type=Application
Categories=Development;IDE;
Terminal=false
StartupNotify=true
EOF
    identify "$HOME/STM32Cube/help/STM32CubeMX.ico" | while read line; do
        res="$HOME/.local/share/icons/hicolor/"$(cut -d ' ' -f3 <<<"$line")"/apps"
        mkdir -p "$res"
        convert "$(cut -d ' ' -f1 <<<"$line")" "$res/STM32CubeMX.png"
    done
}
