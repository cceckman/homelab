# Builder for homelab/cloudlab system configurations.

# Flake-based system image builder from https://hoverbear.org/blog/nix-flake-live-media/
# More info from https://www.tweag.io/blog/2020-07-31-nixos-flakes/
{
  description = "Homelab machine configurations";
  inputs.nixos.url = "github:nixos/nixpkgs/22.11";

  inputs.nixos-wsl.url = "github:nix-community/NixOS-WSL";

  outputs = { self, nixos, nixos-wsl }: {
    nixosConfigurations =
      let rackPi = prev: nixos.lib.nixosSystem (prev // {
        system = "aarch64-linux";
        modules = [
          ./common/rpi.nix
          ./common/users.nix
          ./common/ssh.nix
          ((import common/version.nix) { inherit self; inherit nixos; } )
          ./common/utilities.nix
        ];
      });
    in {
      rpiProvisioning = nixos.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
           ((import provisioning/rpi.nix) nixos)
           ((import common/version.nix) { inherit self; inherit nixos; } )
           ./common/utilities.nix
        ];
      };
      rack4 = rackPi {
        system = "aarch64-linux";
        networking.hostName = "rack4";
      };

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
