#!/bin/sh
#
# This script enables [Syncthing] on a [reMarkable 2] tablet.
#
# The script assumes you've set up SSH to the tablet, as described in
# https://remarkablewiki.com/tech/ssh.
#
# [Syncthing]: https://docs.syncthing.net/dev/building.html
# [reMarkable 2]: https://remarkable.com/
#
set -eu

if ! test "$#" = "1"
then
  echo >&2 "Requires a single argument: reMarkable address"
  echo >&2 "(Typically 10.11.99.1)"
  exit 1
fi

TARGET="$1"
INSTALLPATH="~/syncthing"
VERSION="v1.27.12"

CONTENT="$(mktemp -d)/"
build_bin() {
  # Build syncthing:
  # https://github.com/fako1024/go-remarkable
  # This is where I usually download things - not necessarily GOMODCACHE.
  SRCPATH="$HOME"/r/github.com/syncthing/syncthing
  if ! test -d "$SRCPATH"
  then
    echo >&2 "Downloading syncthing source..."
    mkdir -p "$(dirname "$SRCPATH")"
    git clone \
      --depth 1 \
      https://github.com/syncthing/syncthing.git "$SRCPATH"
  fi

  cd "$SRCPATH"
  git fetch --tags
  git checkout "$VERSION"


  echo >&2 "Building syncthing..."
  GOARM=7 go run build.go \
    -goos linux \
    -goarch arm \
    build
  cp syncthing "$CONTENT"
  cp etc/linux-systemd/system/* "$CONTENT"
  echo >&2 "Updated content in $CONTENT"
}

# Build in a subshell, so cd doesn't move us.
( build_bin )

cat <<EOF >"$CONTENT"/setup.sh
#!/bin/sh
set -eu

INSTALLPATH="\$(realpath $INSTALLPATH)"

# Install files to their proper locations:
ls -lah \$INSTALLPATH
chown -R root:root \$INSTALLPATH

cat <<EOS >\$INSTALLPATH/syncthing.env
STHOMEDIR=\$HOME/.config/syncthing
EOS

if test -f /etc/default/tailscaled
then
echo >&2 "Extending environment file with tailscale data..."
cat <<EOS >>\$INSTALLPATH/syncthing.env
ALL_PROXY=socks5://localhost:1055/
HTTP_PROXY=http://localhost:1055/
http_proxy=http://localhost:1055/
EOS

echo >&2 "Patching systemd unit..."
sed -i \
  -e "/^\\[Service\\]\\$/a EnvironmentFile=\$INSTALLPATH\\/syncthing.env" \
  \$INSTALLPATH/syncthing@.service
fi


echo >&2 "Installing binaries and service definitions..."
set -x

# Link from the /usr paths to our install location;
# the INSTALLPATH won't get clobbered.
ln -sf \$INSTALLPATH/syncthing /usr/bin/syncthing
ln -sf \$INSTALLPATH/syncthing@.service /etc/systemd/system/syncthing@.service
set +x

echo >&2 "Reloading systemd..."
systemctl daemon-reload

echo >&2 "Starting syncthing..."
systemctl enable syncthing@root
systemctl restart syncthing@root

sleep 30
echo >&2 "Serving via Tailscale..."
tailscale serve --bg --https 8384 http://127.0.0.1:8384

EOF
chmod +x "$CONTENT/setup.sh"

echo >&2 "Connecting and uploading..."
ssh -o ConnectTimeout=5 root@"$TARGET" \
  "echo >&2 'Connected to reMarkable!'; rm -rf $INSTALLPATH; mkdir -p $INSTALLPATH" >&2
rsync -avz "$CONTENT" "$TARGET:$INSTALLPATH"

echo >&2 "Running setup script..."
ssh root@"$TARGET" "$INSTALLPATH/setup.sh"

