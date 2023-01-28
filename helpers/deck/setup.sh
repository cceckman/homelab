#!/usr/bin/env bash
# Set up Steam Deck.

# set invocation settings for this script:
# -e: Exit immediately if a command exits with a non-zero status.
# -u: Treat unset variables as an error when substituting.
# -o pipefail: the return value of a pipeline is the status of the last command to exit with a non-zero status, or zero if no command exited with a non-zero status
set -eu -o pipefail

DO_PASSWD=false
DO_TSUP=false
DO_SSH=false

while (( "$#" ))
do
  case "$1" in
    "--passwd")
      DO_PASSWD=true
      ;;
    "--tsup")
      DO_TSUP=true
      ;;
    "--ssh")
      DO_SSH=true
      SSH_URL="https://raw.githubusercontent.com/cceckman/homelab/main/helpers/deck/id_deck.pub"
      ;;
    *)
      echo >&2 "Unrecognized argument $1"
      exit 1
      ;;
  esac
  shift
done

do_passwd() {
  echo >&2 "Please set an admin password: "
  set -x
  passwd
  set +x
  echo >&2 "Thanks! Use that for any future prompts (e.g. sudo)"
}

do_tsup() {
# Derived from gist:
# https://gist.github.com/legowerewolf/1b1670457cfac9201ee9d67840952147

# make system configuration vars available
source /etc/os-release

# save the current directory silently
pushd . > /dev/null

# make a temporary directory, save the name, and move into it
dir="$(mktemp -d)"
cd "${dir}"

echo >&2 "Installing Tailscale: Getting version..."

# get info for the latest version of Tailscale
tarball="$(curl -s 'https://pkgs.tailscale.com/stable/?mode=json' | jq -r .Tarballs.amd64)"
version="$(echo ${tarball} | cut -d_ -f2)"

echo >&2 "Got Tailscale version ${version}. Downloading..."

# download the Tailscale package itself
curl -s "https://pkgs.tailscale.com/stable/${tarball}" -o tailscale.tgz

echo >&2 "done. Installing..."

# extract the tailscale binaries
tar xzf tailscale.tgz
tar_dir="$(echo ${tarball} | cut -d. -f1-3)"
test -d $tar_dir

# create our target directory structure
mkdir -p tailscale/usr/{bin,sbin,lib/{systemd/system,extension-release.d}}

# pull things into the right place in the target dir structure
cp -vrf $tar_dir/tailscale tailscale/usr/bin/tailscale
cp -vrf $tar_dir/tailscaled tailscale/usr/sbin/tailscaled
cp -vrf $tar_dir/systemd/tailscaled.service tailscale/usr/lib/systemd/system/tailscaled.service
sed -i 's/--port.*//g' tailscale/usr/lib/systemd/system/tailscaled.service
sudo mkdir -p /etc/default
sudo touch /etc/default/tailscaled

# write a systemd extension-release file
cat <<EOF >> tailscale/usr/lib/extension-release.d/extension-release.tailscale
SYSEXT_LEVEL=1.0
ID=steamos
VERSION_ID=${VERSION_ID}
EOF

# We don't want these owned by 'deck' in the extension
sudo chown -R root:root tailscale

# create the system extension folder if it doesn't already exist, remove the old version of our tailscale extension, and install our new one
sudo mkdir -p /var/lib/extensions
sudo rm -rf /var/lib/extensions/tailscale
sudo cp -rf tailscale /var/lib/extensions/

# return to our original directory (silently) and clean up
popd > /dev/null
sudo rm -rf "${dir}"

# Something about this is wonky... some "builtin" units disappear on activation
sudo systemctl enable systemd-sysext --now
sudo systemd-sysext merge 2>&1
sudo systemctl daemon-reload > /dev/null

sudo systemctl enable tailscaled --now
sudo tailscale up --qr --operator=deck

echo >&2 "done."
echo >&2 "If updating, reboot or run the following to finish the process: sudo systemctl restart tailscaled"
}

do_ssh() {
  pushd . >/dev/null
  tmp_dir="$(mktemp -d)"
  cd "$tmp_dir"
  # Consume SSH_URL; add it to authorized_keys for deck
  curl -Lo key.txt "$SSH_URL"
  mkdir -p "${HOME}/.ssh"
  touch "${HOME}/.ssh/authorized_keys"
  cat key.txt "${HOME}/.ssh/authorized_keys" | sort -u >newkeys
  mv newkeys "${HOME}/.ssh/authorized_keys"

  # Update sshd config and ensure it's running
  sudo sed -i \
    -e 's/^#? *PermitRootLogin.*$/PermitRootLogin no/' \
    -e 's/^#? *PasswordAuthentication.*$/PasswordAuthentication no/' \
    /etc/ssh/sshd_config
  sudo systemctl enable --now sshd
  sudo systemctl restart sshd
  popd
}

if $DO_PASSWD
then
  do_passwd
fi

if $DO_TSUP
then
  do_tsup
fi

if $DO_SSH
then
  do_ssh
fi
