# Flake fragment (not a module!)
# for racked Raspberry Pis.
{ self, name, nixos, tsproxy, ... } : nixos.lib.nixosSystem {
   system = "aarch64-linux";
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
     tsproxy.nixosModules."aarch64-linux".default
     ./rpi.nix
     ./users.nix
     ./ssh.nix
     ./tailscale.nix
     ./tailscale-autoconnect.nix
     ((import ./version.nix) { inherit self; inherit nixos; } )
     ./utilities.nix
   ] ++ rose;
}


