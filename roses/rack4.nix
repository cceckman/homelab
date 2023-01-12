{ config, pkgs, tsproxy, music-triage, ... } : {
  imports = [
    ../uncommon/music.nix
     tsproxy.nixosModules."aarch64-linux".default
     music-triage.nixosModules."aarch64-linux".default
   ];

  networking.hostId = "9274e809";
  environment.systemPackages = [ pkgs.vim ];
  system.stateVersion = "22.11";
}
