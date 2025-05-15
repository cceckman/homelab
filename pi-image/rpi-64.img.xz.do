
set -eu

DATEVERSION="2025-05-13"

curl --fail -Lo "$3" https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-"$DATEVERSION"/"$DATEVERSION"-raspios-bookworm-arm64-lite.img.xz

