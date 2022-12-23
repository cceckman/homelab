{
  description = "Automatic music ripping and sorting.";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
  flake-utils.lib.eachDefaultSystem
  (system: let
    # to work with older version of flakes
    lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
    # Generate a user-friendly version number.
    version = builtins.substring 0 8 lastModifiedDate;

    pkgs = import nixpkgs { inherit system; };
  in {
    # Provide some binary packages for selected system types.
    packages = rec {
      music-autosort = let
        script-name = "music-autosort";
        # writeShellScriptBin attempts to check syntax, but apparently doesn't
        # know about function definitions?
        script = pkgs.writeScriptBin script-name (builtins.readFile ./music-autosort);
        deps = with pkgs; [ coreutils bash ];
      in pkgs.symlinkJoin {
        name = script-name;
        paths = [ script ] ++ deps;
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = "wrapProgram $out/bin/${script-name} --prefix PATH : $out/bin";
      };
      default = music-autosort;
    };
  });
}
