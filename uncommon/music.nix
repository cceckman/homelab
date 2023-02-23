# NixOS config for music server and associated connectivity.
{ config, options, lib, tsproxy, music-triage, ... } : let
  cfg = config.services.cceckman-musicserver;
  library = "${cfg.musicRoot}/AllMusic";
in {
  imports = [
    ../common/nas.nix
    tsproxy.nixosModules."aarch64-linux".default
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
    # Use an updated Navidrome fork, with a pprof handler, to debug
   #nixpkgs.overlays = [
   #  (import ../overlays/navidrome.nix)
   #];

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
    # But this doesn't work - testing the condition doesn't trigger the
    # automount.
    # systemd.services.navidrome.unitConfig.ConditionPathExists =
    #   lib.mkForce "${cfg.musicRoot}";

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

