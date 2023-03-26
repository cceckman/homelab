# NixOS module for RPi machines.
{ lib, nixos, ... }: {
  # Produce an SD image as collateral:
  imports = [
    "${nixos}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];
  sdImage.compressImage = false;

  # Serial settings:
  # Experience shows that it's a manual step, locking
  #   force_turbo=0
  #   core_freq=250
  # in config.txt. Manual fixup step.

  # Does this help? https://github.com/NixOS/nixpkgs/issues/60101
  # nixpkgs.localSystem = { system = "x86_64-linux"; };

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
