# Mixin: Enable node-level monitoring.
{ ... } : {
  services.prometheus.exporters.node = {
    enable = true;
    # Limit collection to "via Tailscale"
    openFirewall = true;
    firewallFilter = "-i tailscale0";
    extraFlags = ["--collector.disable-defaults"];
    enabledCollectors = [
      # Enabled, from the default set:
      "cpu" "cpufreq" "diskstats" "edac" "filefd" "filesystem"
      "hwmon" "loadavg" "meminfo" "netclass" "netdev" "netstat" "os" "stat"
      "thermal_zone" "time" "timex" "uname" "vmstat" "zfs"
      # And from the non-default set:
      "cgroups" "systemd" "wifi"
    ];
  };
}
