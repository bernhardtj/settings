PERMALINK=https://www.st.com/content/ccc/resource/technical/software/sw_development_suite/group0/0b/05/f0/25/c7/2b/42/9d/stm32cubemx_v6-1-1/files/stm32cubemx_v6-1-1.zip/jcr:content/translations/en.stm32cubemx_v6-1-1.zip

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
    chmod +x ./*.linux
    JAVA_HOME="$(find $HOME/.local/share/JetBrains -type d -name jbr -print -quit)" ./*.linux auto-install.xml
    mv $HOME/STM32Cube/STM32CubeMX $HOME/STM32Cube/STM32CubeMXelf
    printf '#!/bin/bash\nJAVA_HOME="$(find $HOME/.local/share/JetBrains -type d -name jbr -print -quit)" " $HOME/STM32Cube/STM32CubeMXelf" "$@"' >$HOME/STM32Cube/STM32CubeMX
    chmod +x $HOME/STM32Cube/STM32CubeMX
    ln -sf $HOME/STM32Cube/STM32CubeMX $HOME/.local/bin/STM32CubeMX
}
