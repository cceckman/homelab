# Common (client & server) fragment for network-attached storage.
{ config, lib, pkgs, ... } : let
  cfg = config.services.cceckman-nas;
  guest-uid = 995;
  guest-gid = 995;
  restic-server-port = 2222;
in {
  options.services.cceckman-nas = {
    mountpoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/bigdata";
      description = "mountpoint for (local or remote) NAS";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "rack4";
      description = "hostname for the NAS host";
    };
  };

  config = lib.mkMerge [
    # Server fragment:
    (lib.mkIf (config.networking.hostName == cfg.host) {
      environment.systemPackages = [ pkgs.restic pkgs.zfs pkgs.file ];

      # The big storage pool uses ZFS; enable and mount it.
      boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
      boot.supportedFilesystems = [ "zfs" ];
      boot.zfs.devNodes = "/dev/disk/by-id";
      fileSystems."${cfg.mountpoint}" = {
        device = "bigdata";
        fsType = "zfs";
        options = [
          "x-systemd.device-timeout=10s"
          "x-systemd.mount-timeout=10s"
          "nofail"
        ];
      };
      # ZFS wants to use a lot of memory; limit it a bit.
      boot.modprobeConfig.enable = true;
      boot.extraModprobeConfig = ''
        # Limit ARC size to 128MiB, to run safely on small machines
        options zfs zfs_arc_max=${builtins.toString (128 * 1024 * 1024)}
      '';

      # Set up permissions:
      # Add a group and user that get access
      users.groups.shared-disks = {
        gid = 994;
      };
      users.groups.samba-guest = {
        gid = guest-gid;
      };
      users.users.samba-guest = {
        uid = guest-uid;
        isSystemUser = true;
        home = "/home/samba-guest";
        extraGroups = ["shared-disks"];
        description = "Samba guest account";
        group = "samba-guest";
      };

      # Network access
      networking.firewall.enable = true;
      networking.firewall.allowPing = true;
      networking.firewall.allowedTCPPorts = [
        5357  # wsdd
        22    # SSH
        2049  # NFS
      ];
      networking.firewall.allowedUDPPorts = [
        3702 # wsdd
      ];

      # NAS shares, over NFS.
      services.nfs.server.enable = true;
      fileSystems."/export/bigdata" = {
        device = "/mnt/bigdata";
        options = [
          "bind"
          "nofail"
        ];
      };
      # Even with this, may need to set some registry settings to avoid Windows
      # reporting as "read-only":
      # https://superuser.com/questions/103970/how-to-set-identity-for-windows-client-for-nfs-without-identity-server
      # With those keys set to match guest-uid/guest-gid, Windows recognizes
      # itself as having "owners" permissions, and correctly reports !Read-Only
      # in Explorer
      services.nfs.server.exports = ''
      /export/bigdata 100.0.0.0/8(rw,all_squash,anonuid=${builtins.toString guest-uid},anongid=${builtins.toString guest-gid},insecure)
      '';

      # Remote backups
      users.users.restic = {
        isSystemUser = true;
        description  = "Restic backups user";
        group = "restic";
        extraGroups = ["shared-disks"];
        # Need stable UID/GID for permissions to stick.
        # Note: the actual install may use a different name for this...
        uid = config.ids.uids.restic;
      };
      users.groups.restic = {
        gid = config.ids.gids.restic;
      };
      services.restic =
        let backup-options = {
          # This targets a GCS bucket
          repository = "gs:xueckman-backup:restic/";
          # Which means we need an environment file setting the credential
          # location
          environmentFile = "/etc/nixos/secrets/restic/environment";
          # And we'll also need a credentials file on the device

          # Contains encryption password
          passwordFile = "/etc/nixos/secrets/restic/password";

        };
        in {
          backups.remote = backup-options // {
            paths = [
              "${cfg.mountpoint}/perpetual"
            ];
            initialize = true;
            user = "restic";
            extraBackupArgs = [
              "--limit-upload=40960" # 2 MiB/s
              # Allow restic to use a cache; put it on the same bigdata volume
              # though obviously not in the backed-up path!
              "--cache-dir ${cfg.mountpoint}/.cache/restic"
              "--cleanup-cache"
            ];

            timerConfig = {
              OnCalendar = "04:05";
              RandomizedDelaySec = "2h";
            };
          };
          server = {
            enable = true;
            privateRepos = true;
            appendOnly = true;
            listenAddress = ":" + toString(restic-server-port);
            dataDir = "${cfg.mountpoint}/serving/restic-server/";
          };
        };
    })
    # Client fragment:
    (lib.mkIf (config.networking.hostName != cfg.host) {
      # Mount bigdata
      fileSystems."${cfg.mountpoint}" = {
        device = "${cfg.host}.monkey-heptatonic.ts.net:/export/bigdata";
        fsType = "nfs";
        options = let
          # this line prevents hanging on network split
          automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
        in ["${automount_opts}"];
      };
    })
  ];
}

