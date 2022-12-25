{ pkgs, lib, options, ...}:
{
  networking.timeServers = options.networking.timeServers.default ++ [ "time.google.com" ];
  services.chrony.enable = true;
}
