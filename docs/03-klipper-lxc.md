# Klipper LXC containers

One container per printer. Each runs Klipper + Moonraker + Fluidd and owns exactly one USB device.

## Container plan

| Printer | CTID | Hostname | IP | USB port label |
|---|---|---|---|---|
| ender3v2-01 | 201 | klipper-01 | | A |
| ender3v2-02 | 202 | klipper-02 | | B |
| ender3v2-03 | 203 | klipper-03 | | C |

## 1. Create the container

Run on the Proxmox host. `scripts/create-klipper-lxc.sh` wraps this — read it before running it.

```bash
pct create 201 local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst \
  --hostname klipper-01 \
  --cores 2 --memory 2048 --swap 512 \
  --rootfs local-lvm:8 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --features nesting=1 \
  --unprivileged 1 \
  --onboot 1 \
  --start 0
```

Set a DHCP reservation for the container's MAC, or swap `ip=dhcp` for a static
`ip=192.168.1.201/24,gw=192.168.1.1`.

## 2. Pass the USB device through

Unprivileged containers can't see host devices by default. Edit `/etc/pve/lxc/201.conf` on the
**host** and append:

```
# CH340 USB-serial (ttyUSB*) is char major 188; ttyACM* (native USB MCUs) is 166.
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 166:* rwm

# Bind only THIS printer's port. Substitute the by-path value you recorded.
lxc.mount.entry: /dev/serial/by-path/pci-0000:00:14.0-usb-0:2:1.0-port0 dev/printer none bind,optional,create=file
```

Two things worth understanding:

- Binding a **single** device (not all of `/dev/serial`) is what keeps printer 2's board from
  ever being addressable inside container 1. This is the main safety property of the design.
- Inside the container the device appears at a fixed path, `/dev/printer`, regardless of which
  host port it came from. `printer.cfg` then reads `serial: /dev/printer` on every machine —
  identical configs across the farm.

The bind follows the symlink to the real `ttyUSBn`, so if you swap which physical port a printer
is plugged into, update the host path in this file and restart the container.

Restart: `pct stop 201 && pct start 201`. Verify inside: `pct exec 201 -- ls -l /dev/printer`.

### Permissions

The bound device is owned by host `root:dialout`. In an unprivileged container the IDs are
shifted, so the in-container `klipper` user usually can't open it. Simplest correct fix, on the host:

```bash
# Give the container's mapped root read/write on the device via a udev rule
cat > /etc/udev/rules.d/99-klipper-lxc.rules <<'RULE'
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0666"
RULE
udevadm control --reload-rules && udevadm trigger
```

`1a86` is WCH (the CH340). `0666` on a serial device on a dedicated host is an acceptable
tradeoff; if you'd rather not, use a privileged container instead and accept *that* tradeoff.
Pick one deliberately — don't do both.

## 3. Install the stack

Inside the container (`pct enter 201`):

```bash
apt update && apt install -y git sudo curl
adduser --disabled-password --gecos "" klipper
usermod -aG sudo,dialout klipper
su - klipper

git clone https://github.com/dw-0/kiauh.git
./kiauh/kiauh.sh
```

In KIAUH: **Install → Klipper**, then **Moonraker**, then **Fluidd**. Accept defaults; a single
instance per container means no instance-naming complexity.

`scripts/bootstrap-klipper.sh` automates the pre-KIAUH steps.

## 4. Drop in the config

Copy this repo's per-printer config into the container:

```bash
# from your workstation
scp printers/ender3v2-01/printer.cfg   root@<container-ip>:/home/klipper/printer_data/config/
scp printers/ender3v2-01/moonraker.conf root@<container-ip>:/home/klipper/printer_data/config/
```

Then restart Klipper from the Fluidd UI. It will fail until the board is flashed — that's next,
in `docs/04-firmware.md`.

## Repeat for 202 / 203

Identical, changing only: CTID, hostname, IP, and the host-side `lxc.mount.entry` path.
Because the in-container path is always `/dev/printer`, the printer configs differ only in
`[mcu]`-adjacent tuning (PID values, Z offset, endstop positions) — everything structural is shared.
