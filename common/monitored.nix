# Mixin: Enable node-level monitoring.
{ ... } : {
  services.prometheus.exporters.node = {
    enable = true;
    # Limit collection to "via Tailscale"
    openFirewall = true;
    firewallFilter = "-i tailscale0";

    enabledCollectors = [
      # Add from the non-default set:
      "cgroups" "systemd" "wifi"
    ];
  };
}
