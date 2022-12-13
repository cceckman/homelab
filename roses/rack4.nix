{ config, pkgs, ... } : {
  environment.systemPackages = [ pkgs.vim ];

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
  users.groups.mediahd-access.members = [ "navidrome" "cceckman" ];
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
}
