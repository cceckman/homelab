# NixOS module for RPi machines.
{ lib, ... }: {
  # Does this help? https://github.com/NixOS/nixpkgs/issues/60101
  # nixpkgs.localSystem = { system = "x86_64-linux"; };

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
