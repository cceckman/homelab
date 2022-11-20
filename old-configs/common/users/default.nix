# Common user config, as a NixOS module.
{ config, pkgs, ... }: {
  # Allow password changes via `passwd`.
  # TODO: Change to "secrets"-based?
  users.mutableUsers = true;
  users.users.cceckman = {
    isNormalUser = true;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvBMbXOjD7W/+R7pO+XvXLkyjJMfR1mSoBsLtpFHGts cceckman@cromwell-wsl"
    ];
    initialPassword = "*";
  };
  users.users.root.openssh.authorizedKeys.keys =
      config.users.users.cceckman.openssh.authorizedKeys.keys;
}
