# https://search.nixos.org/ for dynamic reference

{ config
, pkgs ? (import ./nixpkgs.nix) {}
, lib
, ... }: {
  nixpkgs.crossSystem.system = "aarch64-linux";
  imports = [
    <nixpkgs/nixos/modules/installer/sd-card/sd-image-aarch64.nix>
    ./default.nix
  ];

  # From https://github.com/lucernae/nixos-pi:
  sdImage.compressImage = false;

  # From https://nixos.wiki/wiki/NixOS_on_ARM/Raspberry_Pi_3:
  # boot.kernelParams = ["console=ttyS1,115200n8"];
  # This doesn't appear to be sufficient;
  # the values from https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/installer/sd-card/sd-image-aarch64.nix
  # are still present, this is just appended.
  # It seems like we need this to be first in order for it to work?
  # We wind up needing to patch it after the fact anyway, so skip it here.

  # hardware.enableRedistributableFirmware = true;
  # networking.wireless.enable = true;
}
