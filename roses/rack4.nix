{ music-triage, config, ... } : {
  networking.hostId = "9274e809";
  system.stateVersion = "22.11";

  imports = [
    music-triage.nixosModules."aarch64-linux".default
    ../uncommon/music.nix
  ];
  # Automatically consume music. systemd path units only work on the local host,
  # so we have to run this on the NAS to get "live" updates.
  services.music-triage.instances = let
    cfg = config.services.cceckman-musicserver;
    incoming = "${cfg.musicRoot}/Incoming";
    library = "${cfg.musicRoot}/AllMusic";
    quarantine = "${cfg.musicRoot}/Quarantine";
  in [
    {
      intake = incoming;
      inherit library;
      inherit quarantine;
    }
  ];
}
