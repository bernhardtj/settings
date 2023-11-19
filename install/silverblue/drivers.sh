#!/bin/bash
case "$(lscpu)" in
*'Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz'* | \
    *'Intel(R) Core(TM) i7-3520M CPU @ 2.90GHz'*)
    pkgs_drivers+=(
        broadcom-wl
    )
    ;;
esac

export pkgs_drivers
