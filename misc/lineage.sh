#!/bin/bash
set -x

prefix=$HOME/lineage_build

mkdir -p "$prefix"/{src,zips,logs,ccache,keys,local_manifests,userscripts}

cat <<'EOF' > "$prefix"/local_manifests/microg.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>
    <project path="vendor/partner_gms" name="lineageos4microg/android_vendor_partner_gms" remote="github" revision="master" />
</manifest>
EOF

cat <<'EOF' > "$prefix"/userscripts/begin.sh
echo userscripts worked
EOF

cat <<'EOF' > "$prefix"/userscripts/before.sh
#/bin/bash
echo running before
EOF
chmod +x "$prefix"/userscripts/{begin,before}.sh

podman run --rm --security-opt=label=disable \
    -e "BRANCH_NAME=lineage-20.0" \
    -e "DEVICE_LIST=instantnoodle" \
    -e "SIGN_BUILDS=true" \
    -e "SIGNATURE_SPOOFING=restricted" \
    -e "WITH_GMS=true" \
    -e "INCLUDE_PROPRIETARY=true" \
    -e "REPO_INIT_ARGS '--depth 1'" \
    -v "$prefix/src:/srv/src" \
    -v "$prefix/zips:/srv/zips" \
    -v "$prefix/logs:/srv/logs" \
    -v "$prefix/ccache:/srv/ccache" \
    -v "$prefix/keys:/srv/keys" \
    -v "$prefix/local_manifests:/srv/local_manifests" \
    -v "$HOME/bk:/mnt" \
    -v "$prefix/userscripts:/root/userscripts" \
    lineageos4microg/docker-lineage-cicd

