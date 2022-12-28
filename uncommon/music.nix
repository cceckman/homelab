# Flake for music server and associated connectivity.
{ ... } : {
  # Mount an external media drive
  boot.supportedFilesystems = [ "ntfs" ];
  users.groups.mediahd-access.members = [ "navidrome" "cceckman" "restic" ];
  fileSystems."/media/mediahd" = {
    device = "/dev/disk/by-uuid/5CA43549A4352744";
    options = [ "rw" "noatime" "users" "nofail" "x-systemd.mount-timeout=5s" ];
  };

  # Enable Navidrome music server;
  # allow tsproxy to authenticate use
  services.navidrome.enable = true;
  services.navidrome.settings = {
    MusicFolder = "/media/mediahd/Music/AllMusic";
    ReverseProxyUserHeader = "X-Webauth-User";
    ReverseProxyWhitelist = "127.0.0.1/32";
    PrometheusEnabled = true;
  };

  # Automatically consume music
  services.music-triage.instances = [
    {
      intake = "/media/mediahd/Music/Incoming";
      library = "/media/mediahd/Music/AllMusic";
      quarantine = "/media/mediahd/Music/Quarantine";
    }
  ];

  # Proxy to Navidrome from Tailscale
  services.tsproxy.instances = [
    {
      hostname = "navidrome";
      target = "127.0.0.1:4533";
      authKeyPath = "/var/secrets/navidrome-proxy-authkey.txt";
    }
  ];

  # Share the media drive over Samba
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
      server string = rack4
      netbios name = rack4
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
}
