#!/usr/bin/env bash
# Create one Klipper LXC on a Proxmox host and wire a single USB device into it.
#
# Run ON THE PROXMOX HOST as root. Read it before you run it — it writes to
# /etc/pve/lxc/<ctid>.conf.
#
# Usage:
#   ./create-klipper-lxc.sh 201 klipper-01 /dev/serial/by-path/pci-0000:00:14.0-usb-0:2:1.0-port0
#
# Find the by-path value with:  ls -l /dev/serial/by-path/
# Use by-path, NOT by-id — see docs/07-networking.md.

set -euo pipefail

CTID="${1:?usage: $0 <ctid> <hostname> <usb-by-path>}"
HOSTNAME="${2:?usage: $0 <ctid> <hostname> <usb-by-path>}"
USB_PATH="${3:?usage: $0 <ctid> <hostname> <usb-by-path>}"

TEMPLATE="${TEMPLATE:-local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst}"
BRIDGE="${BRIDGE:-vmbr0}"
STORAGE="${STORAGE:-local-lvm}"
DISK_GB="${DISK_GB:-8}"
CORES="${CORES:-2}"
MEMORY_MB="${MEMORY_MB:-2048}"
NET="${NET:-dhcp}"   # or e.g. 192.168.1.201/24,gw=192.168.1.1

if [[ ! -e "$USB_PATH" ]]; then
  echo "ERROR: $USB_PATH does not exist. Is the printer powered on and plugged in?" >&2
  echo "Available:" >&2
  ls -l /dev/serial/by-path/ >&2 || echo "  (none)" >&2
  exit 1
fi

if pct status "$CTID" &>/dev/null; then
  echo "ERROR: container $CTID already exists. Refusing to touch it." >&2
  exit 1
fi

if [[ "$NET" == "dhcp" ]]; then
  NETCONF="name=eth0,bridge=${BRIDGE},ip=dhcp"
else
  NETCONF="name=eth0,bridge=${BRIDGE},ip=${NET}"
fi

echo "==> Creating container $CTID ($HOSTNAME)"
pct create "$CTID" "$TEMPLATE" \
  --hostname "$HOSTNAME" \
  --cores "$CORES" --memory "$MEMORY_MB" --swap 512 \
  --rootfs "${STORAGE}:${DISK_GB}" \
  --net0 "$NETCONF" \
  --features nesting=1 \
  --unprivileged 1 \
  --onboot 1 \
  --start 0

CONF="/etc/pve/lxc/${CTID}.conf"
echo "==> Adding USB passthrough to $CONF"
cat >> "$CONF" <<CONFEOF

# --- printer USB passthrough (added by create-klipper-lxc.sh) ---
# 188 = ttyUSB (CH340 and friends), 166 = ttyACM (native-USB MCUs)
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 166:* rwm
# Exactly one device, presented inside the container at the fixed path /dev/printer
lxc.mount.entry: ${USB_PATH} dev/printer none bind,optional,create=file
CONFEOF

echo "==> Starting $CTID"
pct start "$CTID"
sleep 5

echo "==> Verifying /dev/printer inside the container"
if pct exec "$CTID" -- test -e /dev/printer; then
  pct exec "$CTID" -- ls -l /dev/printer
  echo "OK"
else
  echo "WARNING: /dev/printer is missing inside the container." >&2
  echo "Check the udev permissions step in docs/03-klipper-lxc.md." >&2
fi

echo
echo "Next: pct enter $CTID  and run scripts/bootstrap-klipper.sh"
