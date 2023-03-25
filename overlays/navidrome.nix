self: super: {
  # All sorts of fun:
  # https://discourse.nixos.org/t/inconsistent-vendoring-in-buildgomodule-when-overriding-source/9225
  navidrome = let
    overrideVersion = "profile-dev";
    # overrideVersion = "0.48.0";
  in super.buildGoModule {
    inherit (super.navidrome.drvAttrs)
      pname doCheck nativeBuildInputs buildInputs
      buildPhase installPhase postFixup;
    inherit (super.navidrome) meta;

    version = overrideVersion;

    src = super.fetchFromGitHub {
      owner = "cceckman";
      repo = "navidrome";
      rev = "${overrideVersion}";
      hash = "sha256-FO2Vl3LeajvZ8CLtnsOSLXr//gaOWPbMthj70RHxp+Q=";
    };

    vendorSha256 = "sha256-LPoM5RFHfTTWZtlxc59hly12zzrY8wjXGZ6xW2teOFM=";
  };
}
