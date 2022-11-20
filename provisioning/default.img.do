
set -eux

RESULT="$(nix build --no-link --print-out-paths '.#nixosConfigurations.'"$2".config.system.build.sdImage)"
cp "$RESULT"/sd-image/*.img "$3"
