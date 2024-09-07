#!/bin/sh

# Run Restic commands to backup, then prune.
restic backup /mnt/bigdata/perpetual

restic forget \
    --keep-daily 7 \
    --keep-weekly 5 \
    --keep-monthly 24 \
    --keep-yearly 1000 \
    --keep-tag perpetual

restic prune
