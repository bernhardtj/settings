#!/bin/bash
# quilt info

# can only be installed by dnf due to deps (perl, etc), although it is a shell script.

cd $project
mkdir -p patches
# patches/00-mypatch.patch

# create/update series file
mkdir -p .pc
ls patches | sort >.pc/series

quilt push -a

# editing/patch creation workflow
# quilt new 01-mypatch2.patch
# quilt edit path/to/filename
# quilt refresh  # writes to patch
