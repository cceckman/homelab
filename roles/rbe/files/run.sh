#!/bin/sh


. env/bin/activate
set -ex
touch /var/lib/buildgrid/present
ls -la /var/lib/buildgrid
bgd server start server.yml -vvv

