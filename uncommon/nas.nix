# NixOS config for network-attached storage
{ config, pkgs, ... } : {
  environment.systemPackages = [ pkgs.restic ];

  # Portable media harddrive
  boot.supportedFilesystems = [ "ntfs" ];
  fileSystems."/media/mediahd" = {
    device = "/dev/disk/by-uuid/5CA43549A4352744";
    options = [ "rw" "noatime" "users" "nofail" "x-systemd.mount-timeout=5s" ];
  };

  # NAS shares, over Samba
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
      guest account = nobody
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
