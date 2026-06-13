#!/bin/bash
case "$(lscpu)" in
*'Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz'*)
    pkgs_drivers+=(
        broadcom-wl
        #        xorg-x11-drv-nvidia-470xx
        #        akmod-nvidia-470xx
    )
    kargs_drivers+=(
        'acpi_backlight=video'
        'fbcon=nodefer'
    )
    ;;
*'Intel(R) Core(TM) i7-3520M CPU @ 2.90GHz'*)
    pkgs_drivers+=(
        broadcom-wl
    )
    ;;
esac

export pkgs_drivers
