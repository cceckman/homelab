# Builder for homelab/cloudlab system configurations.

# Flake-based system image builder from https://hoverbear.org/blog/nix-flake-live-media/
# More info from https://www.tweag.io/blog/2020-07-31-nixos-flakes/
{
  description = "Homelab machine configurations";
  inputs = {
    nixos.url = "github:nixos/nixpkgs/22.11";
    nixos-wsl.url = "github:nix-community/NixOS-WSL";
    tsproxy = {
      url = "github:cceckman/tsproxy";
      inputs.nixpkgs.follows = "nixos";
    };
    music-triage = {
      url = "path:./music-triage";
      inputs.nixpkgs.follows = "nixos";
    };
  };

  outputs = { self, nixos, nixos-wsl, tsproxy, ... } @ args: {
    nixosConfigurations =
      let rackPi = name: import ./common/rack.nix (args // { inherit name; });
    in {
      rpiProvisioning = nixos.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
           ((import provisioning/rpi.nix) nixos)
           ((import common/version.nix) { inherit self nixos; } )
           ./common/utilities.nix
        ];
      };
      rack4 = rackPi "rack4";

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
