# NixOS module for my dev laptop.
{ pkgs, ... } : {
  imports = [
    ../common/users.nix
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "cceckman";
    startMenuLaunchers = true;
    # Per warning on options.wsl.interop:
    # Need to explicitly register interop if using binfmt.
    interop.register = true;
  };

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking.hostName = "cromwell-nix";

  system.stateVersion = "22.05";

  # Enable crossbuild:
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
