#! /bin/bash -eu
# Set up a Debian / Ubuntu machine to my liking, via Ansible.

sudo apt install -y ansible curl
curl --fail -Lo debootstrap.yaml \
  https://raw.githubusercontent.com/cceckman/homelab/ansible/debootstrap.yaml

sudo ansible-playbook debootstrap.yaml

