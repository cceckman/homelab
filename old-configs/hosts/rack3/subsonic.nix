{ lib, pkgs, ... } : {

  # Subsonic is closed-source ,but we'll still take it.
  # nixpkgs.config.allowUnfree = true;

  # services.airsonic = {
  #   home = "/mnt/qboot/airsonic/home";
  #   # enable = true;
  #   # The default JRE8 wants a lot of UI dependencies -
  #   # including those that are not set up to crossbuild, apparently.
  #   # Pick a minimal JRE per https://nixos.org/manual/nixpkgs/stable/#sec-language-java
  #   # to try to avoid these deps.
  #   jre = pkgs.openjdk8_headless;
  # };

  fileSystems."/mnt/mediahd" = {
    device = "/dev/disk/by-uuid/5CA43549A4352744";
    fsType = "ext4";
  };
}