# Generate a NixOS module for an RPi-in-a-rack.
# Sets the hostname and includes the RPi module.
rackNumber:
let
  name = "rack${builtins.toString rackNumber}";
in
{ ... }: {
  imports = [
    ./rpi.nix
    ./users.nix
    ./ssh.nix
  ];

  networking.hostName = name;
}
