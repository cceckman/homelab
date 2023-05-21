#!/bin/sh
#
# Install push-based backups on a reMarkable 2.

# TODO: The sketch below isn't a great solution.
# Giving the reMarkable SSH access to the NAS is...not great. I have relatively
# little trust in things like restricted shells or even SSH_ORIGINAL_COMMAND
# limitations.
#
# What I'd like is a server that receives these backups, but that _only_ knows
# how to process backups - not run arbitrary commands.
# The Restic rest-server seems like a good candidate:
#   https://github.com/restic/rest-server
# General flow being:
# - reMarkable periodically (frequently?) copies to the rest-server
# - periodic (less frequently?) sync from the rest-server data - as a local
#   repository- to the main (remote) restic repository (?)
#
# - later step: periodic extraction / realization of reMarkable files into
#   Documents tree. (Some duplication of content; but at least PDFs should
#   benefit from dedupe? I think?)


usage() {
  exec >&2
  echo "usage:"
  echo "  $0 <TARGET> <USER>@<HOST>:<DIR>"
  echo "Configure <TARGET> to back up to <HOST>:<DIR>, "
  echo "via a connection as <USER>."
}

if ! test "$#" -eq "2"
then
  usage
  exit 1
fi

set -eu

TARGET="$1"
BACKUP_USER="$(echo "$2" | cut -d'@' -f1)"
BACKUP_HOST="$(echo "$2" | cut -d'@' -f2 | cut -d':' -f1)"
BACKUP_DIR="$(echo "$2" | cut -d':' -f2)"

CONTENT="$(mktemp -d)/"

cat <<EOF >"$CONTENT"/rm2-push-backup.sh
#!/bin/sh
# Push a backup for this reMarkable.

set -eu

# Clean up old, possibly incomplete backups:
ssh "$BACKUP_USER"@"$BACKUP_HOST" -- \
  'find "$BACKUP_DIR" -type d -mindepth 1 -not -name latest -delete'
# Make a copy of the latest backup, to update:
NOW="\$(date -Iminutes)"
ssh "$BACKUP_USER"@"$BACKUP_HOST" -- \
  if test -d "$BACKUP_DIR"/latest; \
    then cp -r "$BACKUP_DIR"/latest "$BACKUP_DIR"/"\$NOW" ; \
  fi

# Update the current snapshot:
rsync --dry-run \
  -avzOP \
  --delete \
  --chown "$BACKUP_USER":"$BACKUP_USER" \
  ~/.local/share/remarkable/xochitl/ \
  "$BACKUP_USER"@"$BACKUP_HOST":"$BACKUP_DIR"/"\$NOW"/

# And atomically replace the previous:
ssh "$BACKUP_USER"@"$BACKUP_HOST" -- \
  mv "$BACKUP_DIR"/"\$NOW" "$BACKUP_DIR"/latest

EOF
chmod +x "$CONTENT"/rm2-push-backup.sh

cat <<EOF >"$CONTENT"/rm2-push-backup.service
[Unit]
Description=Push backups for reMarkable 2
Documentation=https://cceckman.com
Wants=network.target
After=network.target systemd-resolved.service

[Service]
ExecStart=/usr/bin/rm2-push-backup
EOF

cat <<EOF >"$CONTENT"/rm2-push-backup.timer
[Unit]
Description=Schedule for push backups for reMarkable 2
Documentation=https://cceckman.com

[Install]
WantedBy=timers.target

[Timer]
OnBoot=15min
OnCalendar=daily
RandomizedDelaySec=60
Persistent=true
EOF


cat <<EOF >"$CONTENT"/sshconfig
Host "$BACKUP_HOST"
  PasswordAuthentication no
  IdentitiesOnly yes
  IdentityFile %d/.ssh/id_rm2-push-backup
  User "$BACKUP_USER"
  RequestTTY no
EOF

# reMarkable doesn't have ssh-keygen, so we have to do it for them.
ssh-keygen -t ed25519 -N "" -C "$TARGET backups" -f "$CONTENT"/id

cat <<EOF >"$CONTENT"/setup.sh
#!/bin/sh
#
# Script to set up $TARGET for rm2-push-backup.
#
# Set up keys with which to access the target.

set -eu
cd \$(dirname \$0)

mkdir -p ~/.ssh
if ! test -f ~/.ssh/id_rm2-push-backup
then
  mv id ~/.ssh/id_rm2-push-backup
  mv id.pub ~/.ssh/id_rm2-push-backup.pub
else
  rm id*
fi
chmod -R 0700 ~/.ssh

if ! test -f ~/.ssh/config.rm2-push-backup
then
  cp sshconfig ~/.ssh/config.rm2-push-backup
fi
if ! test -f ~/.ssh/config || ! grep -q 'rm2-push-backup' ~/.ssh/config
then
cat <<EOS >>~/.ssh/config

Include .ssh/config.rm2-push-backup
EOS
fi

# Install:
ln -sf \$(pwd)/rm2-push-backup.sh /usr/bin/rm2-push-backup
ln -sf \$(pwd)/rm2-push-backup.service /etc/systemd/system/rm2-push-backup.service
ln -sf \$(pwd)/rm2-push-backup.timer /etc/systemd/system/rm2-push-backup.timer

systemctl daemon-reload
systemctl enable --now rm2-push-backup.timer
EOF
chmod +x "$CONTENT"/setup.sh

# Delete key material after we copy up:
rsync -azP --remove-source-files --chown root:root \
  "$CONTENT"/ \
  "$TARGET":'~/rm2-push-backup/'
ssh "$TARGET" './rm2-push-backup/setup.sh'

echo >&2
echo >&2 "Backups will be performed by $BACKUP_USER on $BACKUP_HOST"
echo >&2 "using key: "
ssh -q "$TARGET" 'cat .ssh/id_rm2-push-backup.pub' >&2


