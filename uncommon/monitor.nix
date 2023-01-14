# On-network monitoring endpoint.
{ ... } :
let
  promStateInVarLib = "prometheus";
  promStateTarget = "/media/qboot/prometheus";
in {
  # Keep the Prometheus state on an external storage, not the root partition.
  system.activationScripts = {
    linkPrometheus = ''
      mkdir -p ${promStateTarget}
      ln -sfn /var/lib/${promStateInVarLib} ${promStateTarget}
    '';
  };

  # Activate Prometheus
  services.prometheus = {
    enable = true;
    stateDir = promStateInVarLib;
    port = 9001;
    scrapeConfigs = [ {
      job_name = "node_exporter";
      dns_sd_configs = [{
        names = builtins.map (x: x + ".monkey-heptatonic.ts.net") [
          "rack3"
          "rack4"
          "rack11"
        ];
        port = 9100;
        type = "AAAA";
      }];
      relabel_configs = [
        {
          source_labels = ["__address__"];
          target_label = "address";
        }
        {
          source_labels = ["__meta_dns_name"];
          target_label = "node";
        }
      ];
    }];
    remoteWrite = [{
      url = "https://prometheus-us-central1.grafana.net/api/prom/push";
      basic_auth = {
        username = "54857";
        password_file = "${promStateTarget}/key.txt";
      };
    }];
  };
}
