{ lib, config, pkgs, ... } :
# From the Tailscale blog: https://tailscale.com/blog/nixos-minecraft/
# Modified to allow injecting the auth key, based on https://nixos.wiki/wiki/NixOS_modules

with lib;

let
  cfg = config.services.tailscale-autoconnect;
in {
  options.services.tailscale-autoconnect = {
    enable = mkEnableOption "Automatic Tailscale connection, enrollment";
    token = mkOption {
      type = types.str;
      default = /var/secrets/tailscale-authkey.txt;
      description = ''
        Path of a file containing a Tailscale authentication key.
        If tailscale-autoconnect is enabled and Tailscale is not already
        authenticated, this token will be read and used to authenticate
        the node(s).
        See https://tailscale.com/kb/1085/auth-keys/ for more on Tailscale
        auth keys.

        Consider using a tool to upload this outside of the Nix store,
        especially if it is not a one-shot key.
      '';
    };
  };

  config = mkIf cfg.enable {
    # make the tailscale command usable to users
    environment.systemPackages = [ pkgs.tailscale pkgs.jq ];

    # create a oneshot job to authenticate to Tailscale
    systemd.services.tailscale-autoconnect =
    let
      remotePath = cfg.token;
    in {
      description = "Automatic connection to Tailscale";

      # make sure tailscale is running before trying to connect to tailscale
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];

      # set this service as a oneshot job
      serviceConfig.Type = "oneshot";

      # have the job run this shell script
      script = with pkgs; ''
        # wait for tailscaled to settle
        sleep 2

        # check if we are already authenticated to tailscale
        status="$(${tailscale}/bin/tailscale status -json | ${jq}/bin/jq -r .BackendState)"
        if [ $status = "Running" ]; then # if so, then do nothing
          exit 0
        fi

        # check if we can use the file
        if ! test -f "${remotePath}"
        then
          echo >&2 "Auth key file ${remotePath} doesn't exist; skipping authentication attempt"
          exit 0
        fi
        if ! test -r "${remotePath}"
        then
          echo >&2 "Auth key file ${remotePath} is present, but not readable"
          exit 1
        fi

        # otherwise authenticate with tailscale
        ${tailscale}/bin/tailscale up -authkey "$(cat ${remotePath})"
      '';
    };
  };
}
