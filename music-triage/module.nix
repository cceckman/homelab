# NixOS module that runs a music-sorting service.
{ config, pkgs, lib, ... } : let
  instance-config = lib.types.submodule {
    options = {
      intake = lib.mkOption {
        type = lib.types.str;
        description = "Intake directory; read and sort files from this path.";
      };
      quarantine = lib.mkOption {
        type = lib.types.str;
        description = "Quarantine directory; place files in this directory if there are errors sorting them.";
      };
      library = lib.mkOption {
        type = lib.types.str;
        description = "Library directory; sort files into this directory.";
      };
      template = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        description = "File-path template for paths within Library.";
        default = null;
      };
    };
  };
  instantiate = { intake, quarantine, library, template } : let
    unit-name = "music-triage-${lib.escapeSystemdPath intake}";
  in {
    services.${unit-name} = {
      description = "Music triage from ${intake} to ${library}";
      path = [ "${pkgs.music-triage}" ];
      script = ''
      music-triage -intake "${intake}" -library "${library}" -quarantine "${quarantine}" -targetTemplate "${template}"
      '';
      wantedBy = ["multi-user.target"];
    };
    paths.${unit-name}.pathConfig = {
      DirectoryNotEmpty = "${intake}";
      MakeDirectory = true;
    };
  };
in {
  options = {
    services.music-triage.instances = lib.mkOption {
      type = lib.types.listOf instance-config;
      description = "Instances of music-triage to run";
      default = [];
    };
  };
  config = lib.mkIf (config.services.music-triage.instances != []) {
    systemd = builtins.foldl' (x: y: (x // y)) {} (
      builtins.map instantiate config.services.music-triage.instances
    );
  };

}
