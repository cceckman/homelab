{ config, pkgs, ... } : {
  environment.systemPackages = [ pkgs.vim pkgs.restic ];

  system.stateVersion = "22.11";

  services.navidrome.enable = true;
  services.navidrome.settings = {
    MusicFolder = "/media/mediahd/Music/AllMusic";
    ReverseProxyUserHeader = "X-Webauth-User";
    ReverseProxyWhitelist = "127.0.0.1/32";
    PrometheusEnabled = true;
  };

  # Support for external media drive
  boot.supportedFilesystems = [ "ntfs" ];
  users.groups.mediahd-access.members = [ "navidrome" "cceckman" "restic" ];
  fileSystems."/media/mediahd" = {
    device = "/dev/disk/by-uuid/5CA43549A4352744";
    options = [ "rw" "noatime" "users" "nofail" "x-systemd.mount-timeout=5s" ];
  };
  # Proxy to Navidrome
  services.tsproxy.instances = [
    {
      hostname = "navidrome";
      target = "127.0.0.1:4533";
      authKeyPath = "/var/secrets/navidrome-proxy-authkey.txt";
    }
  ];

  # Backup the external media drive
  users.users.restic = {
    isSystemUser = true;
    description  = "Restic backups user";
    group = "restic";
  };
  users.groups.restic = {};

  services.restic = {
    backups.remote = {
      passwordFile = "/etc/nixos/secrets/restic/password";
      environmentFile = "/etc/nixos/secrets/restic/environment";
      paths = [
        "/media/mediahd"
      ];
      initialize = true;
      repository = "gs:xueckman-backup:restic/";
      user = "restic";
      extraBackupArgs = [
        "--limit-upload=40960" # 2 MiB/s
      ];

      timerConfig = {
        OnCalendar = "04:05";
        RandomizedDelaySec = "2h";
      };
    };

  };
}
