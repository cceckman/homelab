{ config, pkgs, ... }: {
  # Allow password changes via `passwd`.
  users.mutableUsers = true;
  users.users.cceckman = {
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvBMbXOjD7W/+R7pO+XvXLkyjJMfR1mSoBsLtpFHGts cceckman@cromwell-wsl"
    ];
    extraGroups = [ "wheel" "kvm" "libvirtd" "qemu-libvirtd" ];
  };
  nix.settings.trusted-users = [ "cceckman" ];
  security.sudo.wheelNeedsPassword = false;
  users.users.root.openssh.authorizedKeys.keys =
      config.users.users.cceckman.openssh.authorizedKeys.keys;
}
