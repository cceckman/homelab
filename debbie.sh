#! /bin/bash -eu
# Set up a Debian / Ubuntu machine to my liking, via Ansible.

sudo apt install -y ansible curl
curl -Lo bootstrap.yaml \
  https://raw.githubusercontent.com/cceckman/homelab/tree/ansible/debbootstrap.yaml

ansible-playbook debootstrap.yaml

