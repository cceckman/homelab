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
}
