
set -e

redo-ifchange rpi-64.img.xz
unxz --stdout rpi-64.img.xz >"$3"

