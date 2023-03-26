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
chmod +w "${TARGET}.img"
# Patch up the serial settings:
guestfish -x --rw \
    --add "${TARGET}.img" \
    --mount /dev/sda2:/ \
    <<EOS
mkdir-p /boot/firmware
copy-out /boot/extlinux/extlinux.conf .
EOS
sed -i \
  -e '/APPEND/s/console=[^ ]* //g' \
  -e 's/APPEND.*$/\0 console=ttyS1,115200n8/g' \
  extlinux.conf

guestfish -x --rw \
    --add "${TARGET}.img" \
    --mount /dev/sda2:/ \
    --mount /dev/sda1:/boot/firmware \
    <<EOS
write-append /boot/firmware/config.txt "\nenable_uart=1\n"
write-append /boot/firmware/config.txt "\force_turbo=0\n"
write-append /boot/firmware/config.txt "\ncore_freq=250\n"
copy-in extlinux.conf /boot/extlinux/
EOS

rm extlinux.conf

