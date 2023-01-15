# Common (client & server) fragment for network-attached storage.
{ config, lib, pkgs, ... } : let
  cfg = config.services.cceckman-nas;
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
          "x-systemd.device-timeout=1m"
          "x-systemd.mount-timeout=5m"
          "nofail"
          "x-systemd.automount"
        ];
      };

      # NAS shares, over Samba.
      # Add a group and user that get access
      users.groups.shared-disks = {};
      users.groups.samba-guest = {};
      users.users.samba-guest = {
        isSystemUser = true;
        home = "/home/samba-guest";
        extraGroups = ["shared-disks"];
        description = "Samba guest account";
        group = "samba-guest";
      };

      networking.firewall.enable = true;
      networking.firewall.allowPing = true;
      services.samba.openFirewall = true;
      services.samba-wsdd.enable = true; # make shares visible for windows 10 clients
      networking.firewall.allowedTCPPorts = [
        5357 # wsdd
        22 # SSH
      ];
      networking.firewall.allowedUDPPorts = [
        3702 # wsdd
      ];
      services.samba = {
        enable = true;
        securityType = "user";
        extraConfig = ''
          workgroup = WORKGROUP
          server string = ${config.networking.hostName}
          netbios name = ${config.networking.hostName}
          security = user
          #use sendfile = yes
          #max protocol = smb2
          # note: localhost is the ipv6 localhost ::1
          # https://tailscale.com/kb/1033/ip-and-dns-addresses/
          # 100/8 is what Tailscale uses for IPv4 NAT
          # fd7a:115c:a1e0:ab12::/64 is what Tailscale uses for IPv6
          hosts allow = 100.0.0.0/8, 127.0.0.1, localhost, fd7a:115c:a1e0:ab12::/64
          hosts deny = 0.0.0.0/0
          guest account = samba-guest
          map to guest = bad user
        '';
        shares = {
          bigdata = {
            path = "${cfg.mountpoint}";
            browseable = "yes";
            "read only" = "no";
            "guest ok" = "yes";
            "create mask" = "0644";
            "directory mask" = "0755";
          };
        };
      };

      # Remote backups
      users.users.restic = {
        isSystemUser = true;
        description  = "Restic backups user";
        group = "restic";
      };
      users.groups.restic = {};
      services.restic = {
        backups.remote = {
          # This targets a GCS bucket
          repository = "gs:xueckman-backup:restic/";
          # Which means we need an environment file setting the credentials
          environmentFile = "/etc/nixos/secrets/restic/environment";
          # And we'll also need a credentials file there

          # Contains encryption password
          passwordFile = "/etc/nixos/secrets/restic/password";
          paths = [
            "${cfg.mountpoint}/perpetual"
          ];
          initialize = true;
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
    })
    # Client fragment:
    (lib.mkIf (config.networking.hostName != cfg.host) {
      # Mount bigdata
      environment.systemPackages = [ pkgs.cifs-utils ];
      fileSystems."${cfg.mountpoint}" = {
        device = "//${cfg.host}.monkey-heptatonic.ts.net/bigdata";
        fsType = "cifs";
        options = let
          # this line prevents hanging on network split
          automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s";
          user_opts = "uid=1000,gid=100";
          auth_opts = "password=";
        in ["${automount_opts},${user_opts},${auth_opts}"];
      };
    })
  ];
}

