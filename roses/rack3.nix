{ pkgs, ... } : {
  imports = [
    ../uncommon/monitor.nix
  ];

  networking.hostId = "a0e8453b";
  environment.systemPackages = [ pkgs.vim ];
  system.stateVersion = "22.11";
}
