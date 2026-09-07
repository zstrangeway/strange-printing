#!/usr/bin/env bash
# Prepare a fresh Debian 12 LXC for the Klipper stack, then hand off to KIAUH.
#
# Run INSIDE the container as root:  pct enter <ctid>
# KIAUH is interactive by design; this script only does the deterministic part.

set -euo pipefail

KLIPPER_USER="${KLIPPER_USER:-klipper}"

echo "==> Packages"
apt-get update
apt-get install -y git sudo curl wget python3 python3-venv python3-dev \
  libffi-dev build-essential ca-certificates

echo "==> User: $KLIPPER_USER"
if ! id "$KLIPPER_USER" &>/dev/null; then
  adduser --disabled-password --gecos "" "$KLIPPER_USER"
fi
usermod -aG sudo,dialout,tty "$KLIPPER_USER"

echo "==> Passwordless sudo for $KLIPPER_USER (KIAUH needs it)"
echo "${KLIPPER_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/99-${KLIPPER_USER}"
chmod 440 "/etc/sudoers.d/99-${KLIPPER_USER}"

echo "==> KIAUH"
sudo -u "$KLIPPER_USER" -H bash -c '
  cd ~
  [ -d kiauh ] || git clone --depth 1 https://github.com/dw-0/kiauh.git
'

echo "==> Device check"
if [[ -e /dev/printer ]]; then
  ls -l /dev/printer
else
  echo "WARNING: /dev/printer not present — fix passthrough before installing Klipper." >&2
fi

cat <<'MSG'

Done. Now run KIAUH as the klipper user and install, in this order:

  su - klipper
  ./kiauh/kiauh.sh

    Install -> Klipper
    Install -> Moonraker
    Install -> Fluidd

Then copy this printer's config from the repo:

  scp printers/ender3v2-XX/printer.cfg    root@<this-ip>:/home/klipper/printer_data/config/
  scp printers/ender3v2-XX/moonraker.conf root@<this-ip>:/home/klipper/printer_data/config/

Klipper will not connect until the mainboard is flashed — see docs/04-firmware.md.
MSG
