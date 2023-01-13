# NixOS config for network-attached storage
{ config, pkgs, ... } : {

  environment.systemPackages = [ pkgs.restic pkgs.zfs ];

  # The big storage pool uses ZFS; enable and mount it.
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.zfs.extraPools = [ "bigdata" ];

  # External HDD users ntfs
  boot.supportedFilesystems = [ "ntfs" "zfs" ];

  # Portable media harddrive
  fileSystems."/media/mediahd" = {
    device = "/dev/disk/by-uuid/5CA43549A4352744";
    options = [ "rw" "noatime" "users" "nofail" "x-systemd.mount-timeout=5s" ];
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
      media = {
        path = "/media/mediahd";
        browseable = "yes";
        "read only" = "no";
        "guest ok" = "yes";
        "create mask" = "0644";
        "directory mask" = "0755";
      };
      bigdata = {
        path = "/media/bigdata";
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
        "/media/mediahd"
        "/bigdata"
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
}
