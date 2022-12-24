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
        vendorSha256 = "sha256-Xwd+M5Mil8yPyiZewmHM7tp1sQQIFZYvRmf+6tNZ3hw=";
      };
      default = music-autosort;
    };
    devShells = {
      default = pkgs.mkShell {
        # Also tageditor - though that isn't available on aarch64
        buildInputs = with pkgs; [ go gopls gotools go-tools ffmpeg delve imagemagick ];
      };
    };
    nixosModules.default = import ./module.nix;
    # TODO: Have "check" run tests?
  });
}
