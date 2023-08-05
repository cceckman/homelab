#! /bin/sh
#
# Connect to rack18 (BMC bounce host) via SSH, and forward the web interface.
echo >&2 "Starting local port forwarding..."
echo >&2 "  :8192 BMCWeb"
echo >&2 "  :8006 Proxmox console"

ssh -v \
  -L 8192:192.168.3.190:443 \
  -L 8006:192.168.2.191:8006 \
  rack18 -- "sh -c './ipmitool power on ; read NONE'"

