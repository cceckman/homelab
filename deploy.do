#!/usr/bin/env nix-shell
#! nix-shell -i bash -p nixos-rebuild

set -eux

# TODO: Get targets from nix eval

# We build and deploy onto the same (remote) host;
# even though RPis are underpowered, we avoid cross-building.

for target in rack4
do
  nixos-rebuild build \
    --flake '.#'"$target" \
    --target-host "$target" \
    --build-host "$target" \
    --use-remote-sudo
done

for target in rack4
do
  nixos-rebuild switch \
    --flake '.#'"$target" \
    --target-host "$target" \
    --build-host "$target" \
    --use-remote-sudo
done


