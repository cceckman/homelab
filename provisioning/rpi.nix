# NixOS module generator for the RPi provisioning image.
# Takes the flake's nixos as the input.
nixos: { ... }: {
  imports = [
      "${nixos}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
      ../common/users.nix
      ../common/ssh.nix
  ];

  # Our image burners don't know how to handle zstd, so don't use it.
  sdImage.compressImage = false;
}