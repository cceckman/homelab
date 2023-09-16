#!/bin/sh


. env/bin/activate
set -ex
touch /var/lib/buildgrid/present
ls -la /var/lib/buildgrid
exec bgd server start server.yml -vvv

