#! /bin/bash -eu
# Set up a Debian / Ubuntu machine to my liking, via Ansible.

if test "$1" = "--full"
then
  VARS="-e full_home"
fi

sudo apt install -y ansible curl
curl --fail -Lo debootstrap.yaml \
  https://raw.githubusercontent.com/cceckman/homelab/ansible/debootstrap.yaml

echo >&2 "Starting sudo mode..."
while ! sudo echo >&2 "Got sudo permission!"
do
  echo >&2 "Retry?"
done
# Run this as the current user; "become" only as needed
ansible-playbook $VARS debootstrap.yaml

