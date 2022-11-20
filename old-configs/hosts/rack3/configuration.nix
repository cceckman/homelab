{ config, pkgs, lib, ...} : {
    imports = [
      ../../common          # implicit "default.nix"
      ../../common/rpi.nix  # This is a Raspberry Pi
      ../home.nix           # on the homenet
      ./subsonic.nix        # Subsonic runs here - with particular mountpoints
    ];

    networking.hostName = "rack3";
}
