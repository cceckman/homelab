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

  virtualisation.libvirtd.enable = true;
  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  security.polkit.enable = true;

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  networking.hostName = "cromwell-nix";
  networking.wireless.userControlled.enable = true;
  networking.wireless.enable = true;

  system.stateVersion = "22.05";

  # Enable crossbuild:
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
