# Builds the RPi provisioning image.

# Flake-based version from https://hoverbear.org/blog/nix-flake-live-media/
{
  description = "RPi provisioning image";
  inputs.nixos.url = "github:nixos/nixpkgs/nixos-unstable";
  outputs = { self, nixos }: {
    nixosConfigurations = {
      rpiProvisioning = nixos.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixos}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          common/users.nix
          common/ssh.nix
          provisioning/no-sd-compression.nix
        ];
      };
    };
  };
}
