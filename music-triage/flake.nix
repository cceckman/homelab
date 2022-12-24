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
      music-autosort = pkgs.buildGoModule {
        name = "music-autosort";
        src = ./.;
        runVend = true;
        vendorSha256 = "sha256-7PLkIS0qEaTIbq1vsN3bD2tOXNWZfgMu57B58Ihhnyk=";
      };
      default = music-autosort;
    };
    devShells = {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [ go gopls gotools go-tools ffmpeg tageditor delve imagemagick ];
      };
    };
    # TODO: Have "check" run tests
    # TODO: Have a configurable NixOS service
  });
}
