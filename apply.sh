#!/bin/sh

# Usage: ./apply.sh [ --build-there | -r ] [ <hostame> ]

TARGET=""
REMOTE_BUILD="false"
for arg in "$@"
do
  case "$arg" in
    "--build-there"|"-r") REMOTE_BUILD="true";;
    "-"$) echo >&2 "Unrecognized flag: $arg"; exit 1;;
    *) TARGET="$arg";;
  esac
done

BUILD_ARGS=""
if "$REMOTE_BUILD"
then
  BUILD_ARGS="--build-host ${TARGET.ts}"
fi


if test -n "$TARGET"
then
  nixos-rebuild switch \
    $BUILD_ARGS \
    --use-remote-sudo \
    --target-host ${1}.ts \
    --flake .'#'$TARGET
else
  sudo nixos-rebuild switch --flake .
fi

