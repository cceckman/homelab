#!/bin/bash
#
# Overall setup for reMarkable 2.
#
# This assumes `ssh remarkable` works reliably, even as we make changes.
# I've got https://awbmilne.github.io/blog/SSH-Host-Fallback/ set up with
# priority:
# - USB-Ethernet, with password allowed
#   Allows bootstrapping from password to SSH key, but only when the tablet is
#   plugged in locally
# - Local network, with password disallowed
#   Allows bringing up (or fixing) Tailscale, from WLAN, as long as the tablet
#   is on the same local network and has SSH setup completed
# - Tailscale, with password disallowed
#   Allows operation other than TS-install to proceed from anywhere, to
#   anywhere

set -eux -o pipefail

# make sure we have an SSH key:
KEYFILE="$HOME/.ssh/id_rm2.pub"
if ! test -f "$KEYFILE"
then
  echo >&2 "No SSH key file, generating one..."
  ssh-keygen \
    -t ed25519 \
    -f "$(dirname $KEYFILE)/$(basename -s.pub $KEYFILE)" \
    -C "$(hostname)-to-remarkable"
fi
# Install key:
# For whatever reason, ssh-copy-id doesn't want to work.
<"$KEYFILE" ssh 'remarkable' sh -c 'umask 077 && mkdir -p .ssh && cat - >.ssh/authorized_keys'
# ssh-copy-id -i "$KEYFILE" remarkable

echo >&2 "All done!"

