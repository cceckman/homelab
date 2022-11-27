# NixOS configuration (generator) for my dev laptop.
{ nixos, nixos-wsl, ... } : {
  system = "x86_64-linux";
  modules = [ nixos-wsl.wsl ];

  imports = [
    nixos-wsl.nixosModules.wsl
    ../common/users.nix
  ];

  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "cceckman";
    startMenuLaunchers = true;
  };

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
