#! /bin/sh
#
# sortmusic.sh
# Relocate music into the correct folder based on its tags.
# TODO:
# The future of this script:
# - Make a systemd unit that waits for taildrop events, and puts the contents in
#   Incoming
# - Update this to unpack ZIP files first
# - Wrap this with a systemd unit that uses subsonic permissions, and that
#   activates on "directory not empty"

set -eux

gettag() {
  ffprobe -loglevel error -show_entries format_tags="$1" -of default=noprint_wrappers=1:nokey=1 "$2"
}

organize_all() {
  INTAKE="$1"
  DESTINATION="$2"
  TRIAGE="$3"

  find "$INTAKE" -type f \
  | while read FILE
  do
    organize_one "$FILE" "$DESTINATION" "$TRIAGE"
  done

  # Clean up empty directories.
  # Include "prune" per https://stackoverflow.com/questions/22462124/find-command-in-bash-script-resulting-in-no-such-file-or-directory-error-only
  while test -z "$(find "$INTAKE" -maxdepth 0 -type d -empty)"
  do
    find "$INTAKE" -mindepth 1 -type d -empty -prune -exec rmdir {} \;
  done
}

organize_one() {
  FILE="$1"
  DESTINATION="$2"
  TRIAGE="$3"

  # https://askubuntu.com/questions/226773/how-to-read-mp3-tags-in-shell
  ARTIST="$(gettag album_artist "$FILE")" || true
  ALBUM="$(gettag album "$FILE")" || true
  # Strip "out of" suffix, and any leading zeros
  TRACK="$(gettag track "$FILE" | cut -d/ -f1 | grep -o '[^0].*$')" || true
  if test -z "$ARTIST"
  then
    # Fall back to "artist" if "album_artist" is not set
    ARTIST="$(gettag artist "$FILE")" || true
  fi
  echo >&2 "Found: $ARTIST/$ALBUM/$TRACK at $FILE"

  # https://stackoverflow.com/questions/965053/extract-filename-and-extension-in-bash
  filename=$(basename -- "$FILE")
  extension="${filename##*.}"
  filename="${filename%.*}"

  if test -z "$ARTIST" || test -z "$ALBUM" || test -z "$TRACK"
  then
    echo >&2 "Could not determine some tag for $FILE, placing in triage area"
    TARGET="$TRIAGE/$(basename "$FILE")"
  elif test "$extension" = "m4p"
  then
    echo >&2 "File $FILE appears to be DRM-protected, placing in triage area"
    TARGET="$TRIAGE/$(basename "$FILE")"
  else
    TARGET="$DESTINATION/$ARTIST/$ALBUM/$(printf %02d $TRACK).$extension"
  fi

  mkdir -p "$(dirname "$TARGET")"
  mv "$FILE" "$TARGET"
}

organize_all \
  /mnt/mediahd/Music/Incoming \
  /mnt/mediahd/Music/AllMusic \
  /mnt/mediahd/Music/Triage
]0;cceckman@cromwell-wsl