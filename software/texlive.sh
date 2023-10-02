recipe_bin() {
    echo install-tl
}

recipe_install() {
    mkdir -p ~/.local/share/install-tl
    curl '-#L' https://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet/install-tl-unx.tar.gz | tar -xzC ~/.local/share/install-tl/ --strip 1
    cat >~/.local/bin/install-tl <<<'#!/bin/bash
if [[ $UID -ne 0 ]]; then
    echo "Please run this script as root:

sudo $0"
    exit 1
fi
if !(perl -e "use File::Find" 2>&1 >/dev/null); then
    echo "Please install perl-File-Find for this to work."
    exit 1
fi
pushd ~/.local/share/install-tl
./install-tl "$@"
popd
'
    chmod +x ~/.local/bin/install-tl
}

# https://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet/install-tl-unx.tar.gz
# sudo ./install-tl --paper=letter --texdir=/usr/local/texlive/2023
#
# NB
# this is also packaged in anaconda
#
# !/bin/bash
#
# mkdir -p /tmp/acond
#
# if [[ ! -f /tmp/acond/anaconda.sh ]]; then
# curl '-#Lo' /tmp/acond/anaconda.sh \
# "$(curl '-sL' https://www.anaconda.com/distribution | sed -ne 's@.*\(https:\/\/repo\.anaconda\.com\/archive\/Anaconda3-.*-Linux-x86_64\.sh\)\">64-Bit (x86) Installer.*@\1@p')"
# #https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
# fi
#
# bash /tmp/acond/anaconda.sh -bfp ~/anaconda3
