#!/bin/sh

# Attempt to build an SD image for $2.

TARGET="$1"
if test -z "$TARGET"
then
  echo >&2 "Usage: ./image <hostname>"
  exit 1
fi

set -eu

RESULT="$(nix build --no-link --print-out-paths '.#nixosConfigurations.'"$TARGET".config.system.build.sdImage)"
rm -f "${TARGET}.img"
cp "$RESULT"/sd-image/*.img "${TARGET}.img"
