# NixOS config for music server and associated connectivity.
{ config, options, lib, tsproxy, music-triage, ... } : let
  cfg = config.services.cceckman-musicserver;
  incoming = "${cfg.musicRoot}/Incoming";
  library = "${cfg.musicRoot}/AllMusic";
  quarantine = "${cfg.musicRoot}/Quarantine";
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
    rip = lib.mkEnableOption "automatically rip CDs";
  };
  config = lib.mkIf (config.networking.hostName == cfg.host) {
    # Enable Navidrome music server;
    # allow tsproxy to authenticate use
    services.navidrome.enable = true;
    services.navidrome.settings = {
      MusicFolder = library;
      ReverseProxyUserHeader = "X-Webauth-User";
      ReverseProxyWhitelist = "127.0.0.1/32";
      PrometheusEnabled = true;
      # We're on a low-memory machine; keep caches small.
      TranscodingCacheSize = "0";
      ImageCacheSize = "0";
      Prometheus.Enabled = true;
    };

    # We want to try-to start these units only if the path actually exists.
    # The test - will ? Maybe? - trigger systemd's automount.
    systemd.services.navidrome.unitConfig.ConditionPathExists =
      lib.mkForce "${cfg.musicRoot}";

    # Automatically consume music
    services.music-triage.instances = [
      {
        intake = incoming;
        inherit library;
        inherit quarantine;
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

