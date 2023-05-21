#!/bin/sh
#
# This script enables [restic] backups on a [reMarkable 2] tablet.
#
# [restic]: https://restic.net
# [reMarkable 2]: https://remarkable.com/
#
set -eu

usage() {
  cat <<EOS >&2
usage:
  $0 <REMARKABLE> [<BACKUP_SERVER> <PASSWORD> <USER>]

Sets up <REMARKABLE> to perform regularly-scheduled backups.

If provided, BACKUP_SERVER, PASSWORD, and USER are used to construct the backup
URL. Backups will be sent to

  rest:http://<USER>:<PASSWORD>@<BACKUP_SERVER>

<PASSWORD> is assumed to also be the Restic repository password.

(If these values are not provided, this script assumes an existing
configuration.)

The script will automatically configure Restic to use HTTP and SOCKS proxies if
Tailscale is enabled (per rm2-tailscale).
EOS
}

# Consume arguments:
REMARKABLE="$1"

HAS_CONFIG=false
if test "$#" -eq 4
then
  HAS_CONFIG=true
  BACKUP_SERVER="$2"
  PASSWORD="$3"
  RESTIC_USER="${4}"
elif test "$#" -ne 1
then
  usage
  exit 1
fi
INSTALLPATH="~/restic"

CONTENT="$(mktemp -d)/"
build_restic() {
  # Build Restic for reMarkable
  # https://github.com/fako1024/go-remarkable
  # This is where I usually download things - not necessarily GOMODCACHE.
  RESTICPATH="$HOME"/r/github.com/restic/restic
  RESTICVERSION="v0.15.2"
  if ! test -d "$RESTICPATH"
  then
    echo >&2 "Downloading restic source..."
    mkdir -p "$(dirname "$RESTICPATH")"
    git clone 1 https://github.com/restic/restic.git "$RESTICPATH"
  fi
  (cd "$RESTICPATH" ; git checkout "$RESTICVERSION")

  # Use some of the ldflags from tailscale to keep the size down.
  echo >&2 "Building restic..."
  GOOS=linux GOARCH=arm GOARM=7 \
    go build \
    -o "$CONTENT"/restic \
    -C "$RESTICPATH" \
    -ldflags "-w -s" \
    ./cmd/restic
  echo >&2 "Restic binary up-to-date in $CONTENT"
}

build_restic

# Restic has several configuration files we'll need:
# - Systemd unit - to run the backup
# - Timer file - to trigger execution
# - Environment file - to configure repository, password, and proxy
cat <<EOF >"$CONTENT"/restic.service
[Unit]
Description=Restic backups
Requires=network.target
After=network.target network-online.target

[Service]
EnvironmentFile=/etc/default/restic.env

Type=oneshot
PrivateTmp=true
RuntimeDirectory=restic
CacheDirectory=restic
CacheDirectoryMode=0700
X-RestartIfChanged=false
User=root

ExecStart=/bin/sh -c '/usr/bin/restic backup \
  --cache-dir \$CACHE_DIRECTORY --cleanup-cache \
  /home/root/.config/remarkable/xochitl.conf \
  /home/root/.local/share/remarkable/xochitl/ \
  /usr/bin/xochitl'
EOF

cat <<EOF >"$CONTENT"/restic.timer
[Unit]
Description=Trigger for Restic backups

[Install]
WantedBy=timers.target

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySecs=30
EOF

if "$HAS_CONFIG"
then
cat <<EOF >"$CONTENT"/restic.env
RESTIC_REPOSITORY=rest:http://${RESTIC_USER}:$PASSWORD@$BACKUP_SERVER
RESTIC_PASSWORD=$PASSWORD
EOF
fi

cat <<EOF >"$CONTENT"/setup.sh

set -eu

# Install files to their proper locations:
ls -lah $INSTALLPATH
chown -R root:root $INSTALLPATH

echo >&2 "Updating environment file..."
# If we find Tailscale on the device (per rm2-tailscale), update the environment
# so restic proxies via Tailscale:
# https://tailscale.com/kb/1112/userspace-networking/
if test -f /etc/default/tailscaled && ! grep -q 'PROXY' $INSTALLPATH/restic.env
then
cat <<EOS >>$INSTALLPATH/restic.env
ALL_PROXY=socks5://localhost:1055/
HTTP_PROXY=http://localhost:1055/
http_proxy=http://localhost:1055/
EOS
fi

echo >&2 "Installing binaries and service definitions..."
# Link from the /usr paths to our install location
ln -sf $INSTALLPATH/restic /usr/bin/restic
ln -sf $INSTALLPATH/restic.env /etc/default/restic.env
ln -sf $INSTALLPATH/restic.service /etc/systemd/system/restic.service
ln -sf $INSTALLPATH/restic.timer /etc/systemd/system/restic.timer

echo >&2 "Reloading units and starting timers..."
systemctl daemon-reload
systemctl enable --now restic.timer

EOF
chmod +x "$CONTENT/setup.sh"

echo >&2 "Connecting and uploading..."
ssh -o ConnectTimeout=5 "$REMARKABLE" \
  "echo >&2 'Connected to reMarkable!'; mkdir -p $INSTALLPATH" >&2
rsync -avz --remove-source-files "$CONTENT" "$REMARKABLE:$INSTALLPATH"

echo >&2 "Running setup..."
ssh "$REMARKABLE" "$INSTALLPATH/setup.sh"

