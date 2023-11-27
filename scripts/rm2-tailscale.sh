#!/bin/sh
#
# This script enables [Tailscale] on a [reMarkable 2] tablet.
#
# Tailscale is run in [userspace networking] mode, so any outbound applications
# will need to be configured to proxy via tailscaled.
#
# The script assumes you've set up SSH to the tablet, as described in
# https://remarkablewiki.com/tech/ssh, and that it's locally connected
# (not just via Tailscale) during setup.
#
# [Tailscale]: https://tailscale.com
# [reMarkable 2]: https://remarkable.com/
# [userspace networking]: https://tailscale.com/kb/1112/userspace-networking/
#
set -eu

if ! test "$#" = "1"
then
  echo >&2 "Requires a single argument: reMarkable address"
  echo >&2 "(Typically 10.11.99.1)"
  exit 1
fi

TARGET="$1"
TSINSTALLPATH="~/tailscale"
VERSION="v1.54.0"

CONTENT="$(mktemp -d)/"
build_tailscale() {
  # Build Tailscale:
  # https://github.com/fako1024/go-remarkable
  # This is where I usually download things - not necessarily GOMODCACHE.
  TSPATH="$HOME"/r/github.com/tailscale/tailscale
  if ! test -d "$TSPATH"
  then
    echo >&2 "Downloading tailscale source..."
    mkdir -p "$(dirname "$TSPATH")"
    git clone \
      --depth 1 \
      https://github.com/tailscale/tailscale.git "$TSPATH"
  fi

  cd "$TSPATH"
  git fetch --tags --update-shallow origin "$VERSION"
  git checkout "$VERSION"


  # We're building for a small device. We aren't trying to squeeze onto the root
  # partition, but we still want to leave more space for docs if we can.
  #
  # Use https://tailscale.com/kb/1207/small-tailscale,
  # and tags+flags pulled from build_dist.
  echo >&2 "Building tailscale..."
  GOOS=linux GOARCH=arm GOARM=7 \
    go build \
    -C "$TSPATH" \
    -o "$CONTENT"/tailscale.combined \
    -tags ts_include_cli,ts_omit_aws,ts_omit_tap,ts_omit_kube \
    -ldflags "-w -s" \
    ./cmd/tailscaled
  echo >&2 "Tailscale binary up-to-date in $CONTENT"

  # Capture the service file too.
  cp "$TSPATH"/cmd/tailscaled/tailscaled.service "$CONTENT"
}

# Build in a subshell, so cd doesn't move us.
( build_tailscale )

cat <<EOF >"$CONTENT"/setup.sh
#!/bin/sh
set -eu

# Sometimes Remarkable's OS doesn't update resolv.conf ?
# https://www.reddit.com/r/RemarkableTablet/comments/miogzb/solution_cloud_service_connection_issue_when

# Install files to their proper locations:
ls -lah $TSINSTALLPATH
chown -R root:root $TSINSTALLPATH

echo >&2 "Installing binaries and service definitions..."
set -x
# Link from the /usr paths to our install location;
# the TSINSTALLPATH won't get clobbered.
ln -sf $TSINSTALLPATH/tailscale.combined /usr/bin/tailscale
ln -sf $TSINSTALLPATH/tailscale.combined /usr/sbin/tailscaled
ln -sf $TSINSTALLPATH/tailscaled.service /etc/systemd/system/tailscaled.service
set +x

# Tailscale expects some configuration in a drop-in unit or config files;
# the tailscale.service definition includes PORT and FLAGS variables.
# We oblige!
# The reMarkable kernel doesn't appear to have CONFIG_TUN (no /dev/net/tun),
# so we have to try userspace-networking:
# https://tailscale.com/kb/1112/userspace-networking/
cat <<EOS >/etc/default/tailscaled
PORT=41641
FLAGS="--tun userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055"
EOS


echo >&2 "Reloading systemd..."
systemctl daemon-reload

echo >&2 "Starting tailscale..."
systemctl enable tailscaled
systemctl restart tailscaled
tailscale up
EOF
chmod +x "$CONTENT/setup.sh"

echo >&2 "Connecting and uploading..."
ssh -o ConnectTimeout=5 "$TARGET" \
  "echo >&2 'Connected to reMarkable!'; rm -rf $TSINSTALLPATH; mkdir -p $TSINSTALLPATH" >&2
rsync -avz "$CONTENT" "$TARGET:$TSINSTALLPATH"

echo >&2 "Running setup script..."
# Execute under systemd-run, so even if our network connection hangs up due to
# Tailscale disruption, it'll pick up again when we're done.
ssh "$TARGET" "systemd-run $TSINSTALLPATH/setup.sh"

