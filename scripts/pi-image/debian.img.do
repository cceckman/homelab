set -eu

# Extract the baseline Debian image from the xzip archive.

redo-ifchange debian.xz
xzcat debian.xz >"$3"

