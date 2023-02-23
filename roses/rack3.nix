{ config, ... } : {
  imports = [
    ../uncommon/music.nix
  ];

  services.cceckman-musicserver = {
    musicRoot = "${config.services.cceckman-nas.mountpoint}/perpetual/Music";
  };

  networking.hostId = "a0e8453b";
  system.stateVersion = "22.11";
}
