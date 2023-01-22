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
     ({ pkgs, ... }:  {
       networking.hostName = name;
       services.tailscale-autoconnect.enable = true;
       fileSystems."/media/qboot" = {
         device = "/dev/disk/by-label/QBOOTUSB";
       };
       swapDevices = [{
         device = "/media/qboot/swapfile";
         size = 128;
         # Don't really want unencrypted memory contents on a persistent device.
         randomEncryption.enable = true;
       }];
      environment.systemPackages = [ pkgs.vim ];
     })
     ./nas.nix
     ../uncommon/music.nix
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


