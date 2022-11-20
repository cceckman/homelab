# Template: the Raspberry Pi rack has consistent names & IPs.
let
  rack_cfg = n:
  let
    n_str = builtins.toString n;
  in {
    deployment.targetUser = "root";
    # Assume they're already in ~/.ssh/config
    deployment.targetHost = "rack${n_str}";
  };
in
{
  network = {
    description = "Homelab, pi stack";
  };

  "rack1" = rack_cfg 1;
 #"rack2" = rack_cfg 2;
 #"rack3" = rack_cfg 3;
 #"rack4" = rack_cfg 4;
}
