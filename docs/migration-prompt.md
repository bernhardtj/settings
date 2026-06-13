# dotfiles repository

We are creating a dotfiles repository. Here are important paradigms to consider.

## structure

There are setup folders in setups/. Each setup is its own dotfiles configuration, and inheritence is supported between setups (i.e. linux -> silverblue -> bluefin1) etc. That way there can be different dotfile configurations maintained in parallel. This also allows testing/staging (i.e. bluefin2-testing inherits from bluefin1). The root setup (for inheritance purposes) is called default.

## setups

Each setup has installation files, scripts, and dotfiles. These are identified by filename in a fairly flat structure. We want it to be very similar to what's in the reference folder, wherein the comments at the top of the "apply" file (that used to apply the dotfiles before we introducted the setups structure) explain the filename differences. Notable changes we want to make are 1) installation files are in a folder in the reference, but we want to migrate to a .Justfile structure (propose ideas here) and 2) common/infra files should not be included in each setup and should be tracked in the root project folder.

## on-demand software

The "software" feature is an extension to the old apply functionality in the form of a script. It provides on-demand cli software installation. we want to migrate this to using Just and make it part of the global infra stuff.

## general paradigms we want to enforce

- keep infra stuff with minimum dependencies as possible (all dotfile apply or installation scripts only depend on basic bash, python, curl, etc whatever comes preinstalled on fedora)