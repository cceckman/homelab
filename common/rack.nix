# Flake fragment (not a module!)
# for racked Raspberry Pis.
{ self, name, nixos } : nixos.lib.nixosSystem {
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
     }
     ./rpi.nix
     ./users.nix
     ./ssh.nix
     ./tailscale.nix
     ./tailscale-autoconnect.nix
     ((import ./version.nix) { inherit self; inherit nixos; } )
     ./utilities.nix
   ] ++ rose;
}


