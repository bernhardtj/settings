#!/bin/bash
superraw=$HOME/bk/super
pfx="$HOME/lpmakerpfx"
cachedir="$HOME/.cache/lpmakercache/"
imgstoopen=(system_a.img system_ext_a.img product_a.img)

sizeof() {
    stat -c '%s' "$@"
}

# mounttree <prefix>
mounttree() {
    sync
    mkdir -p "$1/system/"
    pushd "$1" || return
    sudo -s <<EOF
set -e
mount system_a.img system/
mount -o ro vendor_a.img system/vendor/
mount -o ro odm_a.img system/odm/
mount product_a.img system/product/
mount system_ext_a.img system/system_ext/
EOF
    popd || return
} # >/dev/null 2>&1

# umounttree <prefix>
umounttree() {
    sync
    pushd "$1" || return
    sudo -s <<EOF
set -e
umount system/vendor/
umount system/odm/
umount system/product/
umount system/system_ext/
umount system/
EOF
    popd || return
} # >/dev/null 2>&1

# setuptree <prefix>
setuptree() {
    mkdir -p "$1"
    mkdir -p "$cachedir/setuptree"
    if [[ ! -f "$cachedir/setuptree_done" ]]; then
        pushd "$cachedir/setuptree" || return
        lpunpack "$superraw"
        touch "../setuptree_done"
        popd || return
    fi
    cp -r "$cachedir/setuptree"/*.img "$1"
} # >/dev/null 2>&1

# extendimg <size> <img>
extendimg() {
    fallocate -l "$1" "$2"
    resize2fs "$2" "$1"
    e2fsck -yE unshare_blocks "$2" | tail -n 10
} #>/dev/null 2>&1

# cropimg <img>
cropimg() {
    e2fsck -yf "$1"
    resize2fs -M "$1"
    resize2fs "$1" 100M
} #>/dev/null 2>&1

# creategroup <name> <part1> <part2> ... <partN>
creategroup() {
    local groupname
    groupname=$1
    shift
    local addpart
    local totalsize=0
    for addpart in "$@"; do
        printf -- "--partition=%s:none:%s:%s " "$addpart" "$(sizeof "$addpart.img")" "$groupname"
        printf -- "--image=%s=%s " "$addpart" "$addpart.img"
        ((totalsize += "$(sizeof "$addpart.img")"))
    done
    printf -- "--group=%s:%s " "$groupname" "$totalsize"
}

# performlpmake <prefix>
performlpmake() {
    pushd "$1" || return
    cp odm_{a,b}.img
    cp product_{a,b}.img
    cp system_{a,b}.img
    cp system_ext_{a,b}.img
    cp vendor_{a,b}.img
    local lpmake_command
    lpmake_command="lpmake \
--metadata-size 65536 \
--device-size=auto \
--metadata-slots=3 \
$(creategroup google_system_dynamic_partitions_a odm_a product_a system_a system_ext_a vendor_a) \
$(creategroup google_system_dynamic_partitions_b odm_b product_b system_b system_ext_b vendor_b) \
--sparse \
--output ./super.new.img"
    echo "+ $lpmake_command"
    $lpmake_command

    popd || return
}

if [[ $1 == 'start' ]]; then
    printf 'Initializing tree...'
    setuptree "$pfx" && echo 'done!' || echo 'failed!'
    for _img in "${imgstoopen[@]}"; do
        printf 'Extending %s...' "$_img"
        extendimg 2G "$pfx/$_img"
        echo 'done!'
    done
    printf 'Mounting tree...'
    mounttree "$pfx" && echo 'done!' || echo 'failed!'
elif [[ $1 == 'finish' ]]; then
    printf 'Umounting tree...'
    umounttree "$pfx"
    echo 'done!'
    for _img in "${imgstoopen[@]}"; do
        printf 'Truncating %s...' "$_img"
        cropimg "$pfx/$_img"
        echo 'done!'
    done
    echo 'Executing lpmake...'
    performlpmake "$pfx"
elif [[ $1 == 'clean' ]]; then
    echo 'cleaning tree'
    umounttree "$pfx"
    rm -rf "$pfx"
elif [[ $1 == 'cleancache' ]]; then
    echo 'wiping cachedir'
    rm -rf "$cachedir"
fi
