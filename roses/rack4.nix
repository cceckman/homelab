{ config, pkgs, tsproxy, music-triage, ... } : {
  imports = [
    ../uncommon/music.nix
     tsproxy.nixosModules."aarch64-linux".default
     music-triage.nixosModules."aarch64-linux".default
  ];
  environment.systemPackages = [ pkgs.vim pkgs.restic ];

  system.stateVersion = "22.11";

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
