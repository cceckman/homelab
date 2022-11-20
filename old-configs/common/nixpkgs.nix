# Pin nixpkgs, per https://justinas.org/nixos-in-the-cloud-step-by-step-part-1
builtins.fetchGit {
  name = "nixos-22.05-2022-11-02";
  url = "https://github.com/NixOS/nixpkgs";
  ref = "refs/heads/nixos-22.05";
  rev = "b3a8f7ed267e0a7ed100eb7d716c9137ff120fe3";
}

