# NixOS common module: wraps up all the other 'common' config items
# and defines defaults for all OS images.
{ pkgs, ... }: {
  # This is, what, a mutation of configuration.nix on the target machine?

  # Apparently NixOS modules resolve the 'imports' item in...some order?
  # What's the precedence?
  imports = [
    <nixpkgs/nixos/modules/profiles/base.nix>
    ./users
    ./tailscale.nix
  ];

  # Some packages we want around to check if we're making progress
  environment.systemPackages = [ pkgs.htop pkgs.iotop ];

  boot.cleanTmpDir = true;
  nix.settings.auto-optimise-store = true;
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  services.resolved = {
    enable = true;
    dnssec = "false";
  };

  # Always auto-upgrade:
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = true;
  system.autoUpgrade.channel = "https://nixos.org/channels/nixos-22.05";
  system.autoUpgrade.rebootWindow = {
    lower = "03:00";
    upper = "04:00";
  };
  system.autoUpgrade.randomizedDelaySec = "30min";

  # Allow SSH; we deploy as root, so leave it open-with-key
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.kbdInteractiveAuthentication = false;
  services.openssh.permitRootLogin = "prohibit-password";

  # TODO: node-exporter; possibly other every-system configs?
}
