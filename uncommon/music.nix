# NixOS config for music server and associated connectivity.
{ config, options, lib, tsproxy, music-triage, ... } : let
  cfg = config.services.cceckman-musicserver;
in {
  imports = [
    ../common/nas.nix
    tsproxy.nixosModules."aarch64-linux".default
    music-triage.nixosModules."aarch64-linux".default
  ];

  options.services.cceckman-musicserver = {
    host = lib.mkOption {
      type = lib.types.str;
      default = "rack3";
      description = "hostname of the music server";
    };
    musicRoot = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "root of the music library";
    };
  };
  config = lib.mkIf (config.networking.hostName == cfg.host) {
    # Enable Navidrome music server;
    # allow tsproxy to authenticate use
    services.navidrome.enable = true;
    services.navidrome.settings = {
      MusicFolder = "${cfg.musicRoot}/AllMusic";
      ReverseProxyUserHeader = "X-Webauth-User";
      ReverseProxyWhitelist = "127.0.0.1/32";
      PrometheusEnabled = true;
      # We're on a low-memory machine; keep caches small.
      TranscodingCacheSize = "50MB";
      ImageCacheSize = "10MB";
      Prometheus.Enabled = true;
    };

    # Automatically consume music
    services.music-triage.instances = [
      {
        intake = "${cfg.musicRoot}/Incoming";
        library = "${cfg.musicRoot}/AllMusic";
        quarantine = "${cfg.musicRoot}/Quarantine";
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
  };
}

