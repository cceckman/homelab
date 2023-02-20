self: super: {
  # All sorts of fun:
  # https://discourse.nixos.org/t/inconsistent-vendoring-in-buildgomodule-when-overriding-source/9225
  navidrome = let
    overrideVersion = "0.49.3-dev.6";
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
      hash = "sha256-ayquHx6axtUT/QZOvpHp9Jjbud0HEY2/xXxR91sMy4g=";
    };

    vendorSha256 = "sha256-t9R3qGXrZV1AF5epCjh2wi/uTf8g/kyvmaxQFj7xeLc=";
  };
}
