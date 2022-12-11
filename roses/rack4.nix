{ config, pkgs, ... } : {
  environment.systemPackages = [ pkgs.vim ];

  system.stateVersion = "22.11";

  services.navidrome.enable = true;
}
