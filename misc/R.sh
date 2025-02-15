#!/bin/bash

# how I'm doing R
# - conda (r-* packages for binary dist; install.packages() can still be used for noarch stuff)
# - jupyter R notebooks

packages=(
    notebook
    r-irkernel
    r-tidyverse # aka ggplot2
)

conda create -n r-env1 "${packages[@]}"

# may need to run in R shell to setup jupyter stubs
# IRkernel::installspec()
#
