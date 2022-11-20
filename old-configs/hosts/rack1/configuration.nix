{ config, pkgs ? (import ../../common/nixpkgs.nix) {} , lib, ...} : {
    imports = [
      ../../common          # implicit "default.nix"
      ../../common/rpi.nix  # This is a Raspberry Pi
      ../home.nix           # on the homenet
    ];

    networking.hostName = "rack1";
}
