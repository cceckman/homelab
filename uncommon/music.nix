# NixOS config for music server and associated connectivity.
{ ... } :
  let mediaRoot = "/bigdata/persistent"; in {
  imports = [
    ./nas.nix
  ];

  # Enable Navidrome music server;
  # allow tsproxy to authenticate use
  services.navidrome.enable = true;
  services.navidrome.settings = {
    MusicFolder = "${mediaRoot}/Music/AllMusic";
    ReverseProxyUserHeader = "X-Webauth-User";
    ReverseProxyWhitelist = "127.0.0.1/32";
    PrometheusEnabled = true;
  };

  # Automatically consume music
  services.music-triage.instances = [
    {
      intake = "${mediaRoot}/Music/Incoming";
      library = "${mediaRoot}/Music/AllMusic";
      quarantine = "${mediaRoot}/Music/Quarantine";
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
