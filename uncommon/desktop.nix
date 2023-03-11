{ pkgs, lib, ... }: {
  # Uncommon system packages, that I want when doing particular tasks.
  environment.systemPackages = [
    pkgs.ffmpeg
    pkgs.flac
    pkgs.hugo
  ];

  environment.variables = {
      NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.stdenv.cc.cc
      ];
      NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  };
}
