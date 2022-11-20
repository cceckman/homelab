#!/usr/bin/env nix-shell
#!nix-shell -p morph -i bash

set -e

# redo-always
# Normalize working directory, if we aren't running under redo:
cd $(realpath $(dirname $0))
exec 1>&2

# Morph doesn't know what keys to use unless we tell it:
export SSH_IDENTITY_FILE="$(realpath ~/.ssh/id_pis)"

# Reboot all machines.
morph exec ./network.nix reboot
