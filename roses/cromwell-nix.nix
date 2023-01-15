# NixOS module for my dev laptop.
{ pkgs, ... } : {
  imports = [
    ../common/keep.nix
    ../common/nas.nix
    ../common/time.nix
    ../common/tz.nix
    ../common/users.nix
    ../common/utilities.nix
    ../common/wsl2.nix
  ];

  networking.hostName = "cromwell-nix";
  networking.wireless.userControlled.enable = true;
  networking.wireless.enable = true;

  system.stateVersion = "22.05";

  # Enable crossbuild:
  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];
}
