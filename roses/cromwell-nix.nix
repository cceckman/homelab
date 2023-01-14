# NixOS module for my dev laptop.
{ pkgs, ... } : {
  imports = [
    ../common/users.nix
    ../common/wsl2.nix
    ../common/utilities.nix
    ../common/keep.nix
    ../common/tz.nix
    ../common/time.nix
  ];

  networking.hostName = "cromwell-nix";
  networking.wireless.userControlled.enable = true;
  networking.wireless.enable = true;

  system.stateVersion = "22.05";

  # Enable crossbuild:
  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];

  # Mount bigdata
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems."/mnt/bigdata" = {
    device = "//rack4.monkey-heptatonic.ts.net/bigdata";
    fsType = "cifs";
    options = let
      # this line prevents hanging on network split
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
      user_opts = "uid=1000,gid=100";
      auth_opts = "password=";
    in ["${automount_opts},${user_opts},${auth_opts}"];
  };

}
