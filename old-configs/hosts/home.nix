# Shared configuration for the homelab RPis
{ config, ... } : {
  imports  = [
    ../common/tailscale-autoconnect.nix
  ];

  fileSystems."/mnt/qboot" = {
    device = "/dev/disk/by-label/QBOOTUSB";
    fsType = "ext4";
  };
}
