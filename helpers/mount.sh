#! /bin/sh
#
USAGE="
mount.sh <file>.img <directory>

  Mounts all partitions of a given image into <directory>.
  Outputs:
  - <directory>/loop: with the name of the loop device
  - <directory>/<N>, where <N> is the partition number, with the mounted filesystem.
"

if test $# -ne 2
then
  echo >&2 "$USAGE"
  exit 1
fi

IMAGEFILE="$1"
MOUNTPATH="$2"
BASENAME="$(basename -s.img "$IMAGEFILE")"

LOOPDEV=$(sudo -n losetup --show -P -f "$IMAGEFILE")
echo "$LOOPDEV" >"$MOUNTPATH"/loop
echo >&2 "Mounted loopback at $LOOPDEV, putting directories in $MOUNTPATH"
for PART in $(partx -sgo NR $1)
do
  mkdir -p "$MOUNTPATH"/${PART}
  sudo -n mount "${LOOPDEV}p${PART}" "$MOUNTPATH"/${PART}
done

