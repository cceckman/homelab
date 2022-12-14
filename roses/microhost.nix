{ nixos, ... } @ args : nixos.lib.nixosSystem {
  system = "x86_64-linux";
  # Import the virt module from the nixos tree:
  modules = [
    "${nixos}/nixos/modules/virtualisation/google-compute-engine.nix"
  ];
}
