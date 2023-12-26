#! /bin/sh
#
# meta-ansible.sh
# Copyright (C) 2023 cceckman <charles@cceckman.com>
#
# Distributed under terms of the MIT license.
#


sudo apt install ansible
ansible-galaxy install artis3n.tailscale
ansible-galaxy collection install prometheus.prometheus

