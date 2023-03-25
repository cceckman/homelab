#!/bin/sh

# Usage: ./apply.sh [ <hostame> ]

if test -n "$1"
then
  nixos-rebuild switch --build-host ${1}.ts --use-remote-sudo --target-host ${1}.ts --flake .'#'$1
else
  sudo nixos-rebuild switch --flake .
fi

