{ config, pkgs, ... } : {
  environment.systemPackages = [ pkgs.vim ];

  system.stateVersion = "22.11";

  services.navidrome.enable = true;
  services.navidrome.settings = {
    Address = "0.0.0.0";
    MusicFolder = "/media/mediahd/Music/AllMusic";
  };

  # Support for external media drive
  boot.supportedFilesystems = [ "ntfs" ];
  users.groups.mediahd-access.members = [ "navidrome" "cceckman" ];
  fileSystems."/media/mediahd" = {
    device = "/dev/disk/by-uuid/5CA43549A4352744";
    options = [ "rw" "noatime" "users" "nofail" "x-systemd.mount-timeout=5s" ];
  };
}
