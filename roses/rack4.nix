{ config, pkgs, ... } : {
  imports = [
    ../uncommon/music.nix
  ];

  services.cceckman-musicserver = {
    musicRoot = "${config.services.cceckman-nas.mountpoint}/perpetual/Music";
  };

  networking.hostId = "9274e809";
  environment.systemPackages = [ pkgs.vim ];
  system.stateVersion = "22.11";
}
