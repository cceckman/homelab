#! /bin/sh
#
# Automatically rip a CD into /mnt/mediahd/Music/Incoming.
set -eux
exec 2>&1

ALL_RIPS=/mnt/mediahd/Music/cd-rip/
mkdir -p "$ALL_RIPS"

# Rip to this directory, on the same FS as the music library;
# move to Incoming (for sorting) when done with the whole CD, not before.
RIPDIR="$(mktemp -d -p "$ALL_RIPS")"

cd "$RIPDIR" # By default, rips into the local directory.

abcde \
  -a cddb,embedalbumart,move,clean \
  -d /dev/cdrom \
  -o flac \
  -NV
# Wait until abcde is done before ejecting; otherwise, get...SIGTERM?
eject

cd ..
mv "$RIPDIR" /mnt/mediahd/Music/Incoming
# And now it's up to the sortmusic unit!
]0;cceckman@cromwell-wsl
