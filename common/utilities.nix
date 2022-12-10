{ config, pkgs, ... }: {
  # Common system packages.
  environment.systemPackages = [
    pkgs.curl
    pkgs.git
  ];

  # Enable nix flakes
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
