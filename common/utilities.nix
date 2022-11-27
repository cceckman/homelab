{ config, pkgs, ... }: {
  # Common system packages.
  environment.systemPackages = [
    pkgs.curl
    pkgs.vim
    pkgs.git
  ];
}
