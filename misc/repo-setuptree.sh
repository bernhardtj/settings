#!/bin/bash

set -e

if [[ ! $1 ]]; then
    echo 'please supply directory' >&2
    exit 1
fi

mkdir -p "$1"
pushd "$1"

cat <<'EOF' >default.xml
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

<remote  name="github" fetch="https://github.com" />

<default revision="main"
         remote="github"
         sync-c="false"
         sync-s="true"
         sync-tags="true"
         sync-j="4"/>

<!-- <project alias="myproj" path="/path/to/folder" name="user/project" remote="github" revision="main" /> -->
</manifest>
EOF

cat <<'EOF' >.gitignore
*
!.gitignore
!default.xml
EOF

set -x
git init
git add --all
git commit -m 'initial'
repo init -u .git
set +x

popd
