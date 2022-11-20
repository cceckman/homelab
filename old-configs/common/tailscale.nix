{ pkgs, ... }: {
  # Use tailscale:
  environment.systemPackages = [ pkgs.tailscale ];
  services.tailscale.enable = true;

  # And accept Tailscale's warning about exit node routing:
  networking.firewall.checkReversePath = "loose";
}