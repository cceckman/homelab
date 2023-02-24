{ config, ... } : {
  networking.hostId = "9274e809";
  system.stateVersion = "22.11";

  imports = [
    ../uncommon/monitor.nix
  ];
}
