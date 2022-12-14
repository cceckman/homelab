{ nixos, self, ... } @ args : nixos.lib.nixosSystem {
  system = "x86_64-linux";

  modules = [
    {
      networking.hostName = "microhost";
      services.tailscale-autoconnect.enable = true;
      system.stateVersion = "22.11";

      fileSystems."/mnt/backup" = {
        device = "/dev/disk/by-uuid/1165b156-6e59-4072-8ba3-5991f3f33259";
      };
    }
    # Import the virt module from the nixos tree:
    "${nixos}/nixos/modules/virtualisation/google-compute-image.nix"
    # And a bunch of standard imports:
    ./../common/users.nix
    ./../common/ssh.nix
    ./../common/tailscale.nix
    ./../common/tailscale-autoconnect.nix
    ((import ./../common/version.nix) { inherit self; inherit nixos; })
    ./../common/utilities.nix
  ];
}
