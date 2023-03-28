{ pkgs, ... }: {
  # Allow SSH, key-only.
  # We have userspace set up to allow passwordless sudo, so we don't need
  # direct root login.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;
  services.openssh.settings.KbdInteractiveAuthentication = false;
  services.openssh.settings.PermitRootLogin = "no";
}
