{ pkgs, ... }: {
  # Allow SSH, key-only.
  # We have userspace set up to allow passwordless sudo, so we don't need
  # direct root login.
  services.openssh.enable = true;
  services.openssh.passwordAuthentication = false;
  services.openssh.kbdInteractiveAuthentication = false;
  services.openssh.permitRootLogin = "no";
}
