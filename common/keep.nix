{ ... } : {
  # Per direnv setup guide: keep things around longer.
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
}
