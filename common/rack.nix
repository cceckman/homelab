# Flake fragment (not a module!)
# for racked Raspberry Pis.
{ self, nixos, name, ... } @ args : nixos.lib.nixosSystem {
  system = "aarch64-linux";
  specialArgs = args;
  modules =
     let
       path = ./../roses/${name}.nix;
       rose = if builtins.pathExists path then [ path ] else [];
     in
   [
     {
       networking.hostName = name;
       services.tailscale-autoconnect.enable = true;
       fileSystems."/media/qboot" = {
         device = "/dev/disk/by-label/QBOOTUSB";
       };
     }
     ./rpi.nix
     ./monitored.nix
     ./users.nix
     ./ssh.nix
     ./tailscale.nix
     ./tailscale-autoconnect.nix
     ((import ./version.nix) { inherit self; inherit nixos; } )
     ./utilities.nix
     ./tz.nix
   ] ++ rose;
}


