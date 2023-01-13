#!/bin/sh
#
# Initialization script to put Nix and home-manager on Remarkable.
#
# Based on:
#   https://github.com/siraben/nix-remarkable
#   https://nix-community.github.io/home-manager/index.html#sec-install-standalone
#


# Start up by setting up passwordless SSH to root-on-remarkable; then:

cat <<EOF | ssh root@remarkable.local

EOF
