#!/bin/bash

if lscpu | grep 'Intel(R) Core(TM) i7-3770 CPU @ 3.40GHz' >/dev/null 2>/dev/null; then
    pkgs_drivers+=(
        broadcom-wl
    )
fi

export pkgs_drivers
