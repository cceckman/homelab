# On-network monitoring endpoint.
{ ... } :
let
  promStateInVarLib = "prometheus";
  promStateTarget = "/media/qboot/prometheus";
  promPort = 9001;
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
    port = promPort;
    scrapeConfigs = [ {
      job_name = "node_exporter";
      dns_sd_configs = [{
        names = builtins.map (x: x + ".monkey-heptatonic.ts.net") [
          "rack3"
          "rack4"
          "rack11"
        ];
        port = 9100;
        type = "A";
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
    }
    {
      job_name = "prometheus";
      static_configs = [{ targets = ["localhost:${toString promPort}"]; }];
    }
  ];
    remoteWrite = [{
      url = "https://prometheus-us-central1.grafana.net/api/prom/push";
      basic_auth = {
        username = "54857";
        password_file = "${promStateTarget}/key.txt";
      };
    }];
  };
}
