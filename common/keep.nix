{ ... } : {
  # Per direnv setup guide: keep things around longer.
  nix.extraOptions = ''
    keep-outputs = true
    keep-derivations = true
  '';
  # But, auto-optimize via hardlinks, to save some space:
  nix.settings.auto-optimise-store = true;
}
