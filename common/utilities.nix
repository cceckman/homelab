{ config, pkgs, ... }: {
  # Common system packages.
  environment.systemPackages = [
    pkgs.curl
    pkgs.git
    pkgs.htop
    pkgs.dig
    pkgs.xz
    pkgs.at
  ];

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
