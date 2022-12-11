# Builder for homelab/cloudlab system configurations.

# Flake-based system image builder from https://hoverbear.org/blog/nix-flake-live-media/
# More info from https://www.tweag.io/blog/2020-07-31-nixos-flakes/
{
  description = "Homelab machine configurations";
  inputs.nixos.url = "github:nixos/nixpkgs/22.11";

  inputs.nixos-wsl.url = "github:nix-community/NixOS-WSL";

  outputs = { self, nixos, nixos-wsl }: {
    nixosConfigurations =
      let rackPi = name: nixos.lib.nixosSystem {
        system = "aarch64-linux";
        modules =
          let
            path = ./roses/${name}.nix;
            rose = if builtins.pathExists path then [ path ] else [];
          in
        [
          {
            networking.hostName = name;
            services.tailscale-autoconnect.enable = true;
          }
          ./common/rpi.nix
          ./common/users.nix
          ./common/ssh.nix
          ./common/tailscale.nix
          ./common/tailscale-autoconnect.nix
          ((import common/version.nix) { inherit self; inherit nixos; } )
          ./common/utilities.nix
        ] ++ rose;
      };
    in {
      rpiProvisioning = nixos.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
           ((import provisioning/rpi.nix) nixos)
           ((import common/version.nix) { inherit self; inherit nixos; } )
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
