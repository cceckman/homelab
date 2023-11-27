#! /bin/sh

set -eux

ansible-galaxy collection install --upgrade \
  prometheus.prometheus \
  community.general

ansible-galaxy role install --upgrade \
  artis3n.tailscale


