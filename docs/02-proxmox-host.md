# Proxmox host setup

Host: **Lenovo ThinkCentre M710s** (SFF), model `10M70030US`.

## BIOS first

Reboot, press **F1** for BIOS setup. Set these before installing anything:

| Setting | Value | Why |
|---|---|---|
| Intel Virtualization Technology (VT-x) | **Enabled** | Proxmox needs it for VMs. LXC doesn't, but you'll want the option. |
| VT-d | **Enabled** | Needed if you ever pass a PCIe device through |
| Secure Boot | **Disabled** | Proxmox's kernel isn't signed for it |
| Boot mode | **UEFI** | |
| **After Power Loss** | **Power On** | A print farm host must come back on its own after an outage. Default is "Power Off". |
| Wake on LAN | Enabled (optional) | Lets you power the farm on remotely |
| Fan control | Quiet/Balanced | It'll be sitting near the printers |

The "After Power Loss → Power On" one is easy to skip and the one you'll regret. Containers are
already set `--onboot 1`, so the whole farm recovers unattended from a power blip.

## Install

1. Flash the Proxmox VE ISO to a USB stick, boot the mini-PC, install to the internal disk.
2. Give the host a **static IP** (or a DHCP reservation). Record it in `docs/07-networking.md`.
3. After first boot, log in over SSH as root.

## Post-install prep

```bash
# 1. Switch to the no-subscription repos (the enterprise repo 401s without a licence)
cat > /etc/apt/sources.list.d/pve-no-subscription.list <<'REPO'
deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription
REPO
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/ceph.list

apt update && apt full-upgrade -y
reboot
```

```bash
# 2. Fetch the Debian 12 LXC template we'll clone containers from
pveam update
pveam available | grep debian-12
pveam download local debian-12-standard_12.7-1_amd64.tar.zst
```

```bash
# 3. Useful host tools
apt install -y usbutils lsof lm-sensors
```

```bash
# 4. Confirm what this box actually is
lscpu | grep 'Model name'
free -h
lsblk -o NAME,SIZE,ROTA,MODEL     # ROTA=1 -> spinning disk, consider an SSD
```

If the boot device is a spinning HDD, strongly consider a SATA SSD before going further —
reinstalling Proxmox later means rebuilding every container. See `docs/01-hardware-inventory.md`.

## Identify the printer USB ports before creating containers

Plug in **one** printer, then:

```bash
ls -l /dev/serial/by-path/
lsusb
dmesg | tail -20
```

You want the `by-path` entry, which looks like:

```
/dev/serial/by-path/pci-0000:00:14.0-usb-0:2:1.0-port0 -> ../../ttyUSB0
```

That path is tied to the **physical port**, so it stays stable across reboots and across
identical CH340 chips that share a serial number. Record one path per printer in
`docs/07-networking.md` and put a physical label on each host USB port.

Do this one printer at a time so you know which path is which.

## Storage

Default LVM-thin (`local-lvm`) for container root disks is fine. Keep containers small
(8 GB) and mount a shared gcode directory only if you later want cross-printer job staging —
not needed for the initial build.

## Backups

Set up a scheduled `vzdump` of all three containers to `local` (or better, an external target)
once they exist: **Datacenter → Backup → Add**, weekly, mode `snapshot`, keep 3.
The authoritative copy of the *configs* lives in this repo — see `docs/08-runbook.md`.
