# NixOS module generator for configurationRevision.
# Encapsulates the pattern in https://www.tweag.io/blog/2020-07-31-nixos-flakes/ - 
# closes over self.rev and nixpkgs to get the relevant tools.
{ self, nixos }:
{ lib, ...}: {
  system.configurationRevision = lib.mkIf (self ? rev) self.rev;
}