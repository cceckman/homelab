#!/bin/bash -eux

# redo-always
# Normalize working directory; we aren't running under redo.
cd $(realpath $(dirname $0))
exec 1>&2

# Manual setup steps for each machine:
# - Make the build not reproducible:
#   nix-channel --add https://nixos.org/channels/nixos-22.05 nixos

list_targets() {
  nix-instantiate --eval --json -E '
    builtins.filter (x: x != "network")
      (builtins.attrNames (import ./network.nix))' \
  | jq -r '.[]'
}

target_string() {
  TARGET_USER="$(nix-instantiate --eval --json -E "
      (import ./network.nix)
      ."$1"
      .deployment.targetUser" | jq -r '.')"
  TARGET_HOST="$(nix-instantiate --eval --json -E "
    (import ./network.nix)
    ."$1"
    .deployment.targetHost" | jq -r '.')"
  echo "${TARGET_USER}@${TARGET_HOST}"
}

# Stage files on the target
stage_files() {
  local TARGET="$(target_string $1)"
  ssh "$TARGET" \
    "mkdir -p /var/secrets/ \\
      && chmod 0700 /var/secrets \\
      && rm -rf /var/secrets/* \\
      && mkdir -p /etc/nixos/configuration.d \\
      && chmod 0755 /etc/nixos/configuration.d \\
      && rm -rf /etc/nixos/configuration.d/* "
  scp -r \
    ../../hosts \
    "$TARGET":/etc/nixos/configuration.d
  scp -r ../../common \
    "$TARGET":/etc/nixos/configuration.d
  if find ../../secrets/ -mindepth 1 | grep -v .gitignore >/dev/null
  then
    chmod 0600 ../../secrets/*
    scp -rp ../../secrets/* \
      "$TARGET":/var/secrets
  fi

  echo "import ./configuration.d/hosts/$1/configuration.nix" \
    | ssh "$TARGET" \
    "touch /etc/nixos/configuration.nix \\
      && chmod 0644 /etc/nixos/configuration.nix \\
      && cat - >/etc/nixos/configuration.nix"
}

update_nix() {
  local TARGET="$(target_string $1)"
  ssh "$TARGET" 'nix-channel --update && nixos-rebuild dry-build'
}

list_targets \
| while read TARGET
do
  stage_files "$TARGET"
  update_nix "$TARGET"
done
