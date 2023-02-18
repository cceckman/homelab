self: super: {
  # All sorts of fun:
  # https://discourse.nixos.org/t/inconsistent-vendoring-in-buildgomodule-when-overriding-source/9225
  navidrome = let
    overrideVersion = "0.49.3-dev.1";
  in super.buildGoModule {
    inherit (super.navidrome.drvAttrs)
      pname doCheck nativeBuildInputs buildInputs
      buildPhase installPhase postFixup;
    inherit (super.navidrome) meta;

    version = overrideVersion;

    src = super.fetchFromGitHub {
      owner = "cceckman";
      repo = "navidrome";
      rev = "v${overrideVersion}";
      hash = "sha256-kuOqRzT+jznr6MadNbpGzj1DPzX3vky1DoDliXFeM/c=";
    };

    vendorSha256 = "sha256-t9R3qGXrZV1AF5epCjh2wi/uTf8g/kyvmaxQFj7xeLc=";
  };
}
