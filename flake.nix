# Builder for homelab/cloudlab system configurations.

# Flake-based system image builder from https://hoverbear.org/blog/nix-flake-live-media/
# More info from https://www.tweag.io/blog/2020-07-31-nixos-flakes/
{
  description = "Homelab machine configurations";
  inputs = {
    nixos.url = "github:nixos/nixpkgs/master";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    tsproxy = {
      url = "github:cceckman/tsproxy";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, nixos, nixos-wsl, tsproxy, ... } @ args: {
    nixosConfigurations =
      let rackPi = name: import ./common/rack.nix (args // { inherit name; });
    in {
      rack3 = rackPi "rack3";
      rack4 = rackPi "rack4";
      provision = rackPi "provision";
      clock = rackPi "clock";

      cromwell-nix = nixos.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./roses/cromwell-nix.nix
        ];
      };
    };
  };
}
