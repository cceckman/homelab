{ pkgs, ... } : {
  wsl = {
    enable = true;
    wslConf.automount.root = "/mnt";
    defaultUser = "cceckman";
    startMenuLaunchers = true;
    # Per warning on options.wsl.interop:
    # Need to explicitly register interop if using binfmt.
    interop.register = true;
  };

  # NixOS appears to run afoul of https://github.com/microsoft/WSL/issues/7149-
  # and we want nested virtualization.
  # Unit from https://nixos.wiki/wiki/Extend_NixOS
  # This doesn't work, though, so hold off for now.
 #systemd.services.wsl-kvm-fixup = {
 #  wantedBy = [ "multi-user.target" ];
 #  description = "Fix kvm permissions for WSL";
 #  serviceConfig = {
 #    Type = "simple";
 #    # Still issues here - need to execute multiple programs, this just is a single exec
 #    ExecStart = "${pkgs.coreutils}/bin/chown root:kvm /dev/kvm && ${pkgs.coreutils}/bin/chmod 660 /dev/kvm";
 #  };

 #};
}

