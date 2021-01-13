recipe_bin() {
    cat <<EOF
arm-none-eabi-addr2line
arm-none-eabi-ar
arm-none-eabi-as
arm-none-eabi-c++
arm-none-eabi-c++filt
arm-none-eabi-cpp
arm-none-eabi-elfedit
arm-none-eabi-g++
arm-none-eabi-gcc
arm-none-eabi-gcc-ar
arm-none-eabi-gcc-nm
arm-none-eabi-gcc-ranlib
arm-none-eabi-gcov
arm-none-eabi-gcov-dump
arm-none-eabi-gcov-tool
arm-none-eabi-gdb
arm-none-eabi-gdb-add-index
arm-none-eabi-gdb-add-index-py
arm-none-eabi-gdb-py
arm-none-eabi-gprof
arm-none-eabi-ld
arm-none-eabi-ld.bfd
arm-none-eabi-nm
arm-none-eabi-objcopy
arm-none-eabi-objdump
arm-none-eabi-ranlib
arm-none-eabi-readelf
arm-none-eabi-size
arm-none-eabi-strings
arm-none-eabi-strip
EOF
}

recipe_install() {
    URL=https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads
    LINK="$(curl -s $URL | grep -m 1 '64-bit.*Linux' | cut -d '"' -f2 | cut -d '?' -f1)"
    curl '-#L' "https://developer.arm.com$LINK" | tar xjC "$HOME/.local" --strip 1
    cat <<'EOF'
GCC is installed! Remember to do this to your CMakeLists_template.txt:
sed -i s,\ arm-none-eabi,\ $HOME/.local/bin/arm-none-eabi,g CMakeLists_template.txt
EOF
}
