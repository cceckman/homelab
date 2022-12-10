# NixOS module for my dev laptop.
{ pkgs, ... } : {
  imports = [
    ../common/users.nix
    ../common/wsl2.nix
    ../common/utilities.nix
    ../common/keep.nix
  ];

  networking.hostName = "cromwell-nix";
  networking.wireless.userControlled.enable = true;
  networking.wireless.enable = true;

  system.stateVersion = "22.05";

  # Enable crossbuild:
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
