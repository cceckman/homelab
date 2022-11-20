# Nix module configuring our RPis for the homelab.
{ config
, pkgs ? (import ./nixpkgs.nix) {}
, lib
, ... } : {
  nixpkgs.crossSystem.system = "aarch64-linux";

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  # The SD image we make has these filesystems:
  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
  };
  fileSystems."/boot/firmware" = {
    device = "/dev/disk/by-label/FIRMWARE";
    fsType = "vfat";
  };
}
