{ music-triage, config, ... } : let
  musicRoot = "/mnt/bigdata/perpetual/Music";
  incoming = "${musicRoot}/Incoming";
  library = "${musicRoot}/AllMusic";
  quarantine = "${musicRoot}/Quarantine";
in {
  networking.hostId = "9274e809";
  system.stateVersion = "22.11";

  imports = [
    music-triage.nixosModules."aarch64-linux".default
    ../uncommon/music.nix
    ../uncommon/monitor.nix
  ];

  # Automatically consume music. systemd path units only work on the local host,
  # so we have to run this on the NAS to get "live" updates.
  services.music-triage.instances = [
    {
      intake = incoming;
      inherit library;
      inherit quarantine;
    }
  ];
}
