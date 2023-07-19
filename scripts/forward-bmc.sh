#! /bin/sh
#
# Connect to rack18 (BMC bounce host) via SSH, and forward the web interface.
echo >&2 "Starting local port forwarding from :8192 to BMC HTTPS interface..."
ssh -N -v \
  -L 8192:192.168.3.190:443 \
  rack18

