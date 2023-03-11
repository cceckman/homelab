# Builder for homelab/cloudlab system configurations.

# Flake-based system image builder from https://hoverbear.org/blog/nix-flake-live-media/
# More info from https://www.tweag.io/blog/2020-07-31-nixos-flakes/
{
  description = "Homelab machine configurations";
  inputs = {
    nixos.url = "github:nixos/nixpkgs/nixos-22.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    tsproxy = {
      url = "github:cceckman/tsproxy";
      inputs.nixpkgs.follows = "nixos";
    };
    nix-ld.url = "github:Mic92/nix-ld";
    nix-ld.inputs.nixpkgs.follows = "nixos";
  };

  outputs = { self, nixos, nixos-wsl, tsproxy, nix-ld, ... } @ args: {
    nixosConfigurations =
      let rackPi = name: import ./common/rack.nix (args // { inherit name; });
    in {
      rack3 = rackPi "rack3";
      rack4 = rackPi "rack4";
      clock = rackPi "clock";

      cromwell-nix = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nix-ld.nixosModules.nix-ld
          nixos-wsl.nixosModules.wsl
          ./roses/cromwell-nix.nix
        ];
      };
    };
  };
}
