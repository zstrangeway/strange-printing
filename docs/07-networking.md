# Networking

## Address plan

Static leases (DHCP reservation by MAC, set on the router) keep this stable without
hand-configuring each container.

| Host | Role | IP | Ports |
|---|---|---|---|
| pve-01 | Proxmox host | | 8006 (web UI), 22 |
| klipper-01 | LXC 201 → ender3v2-01 | | 80 (Fluidd), 7125 (Moonraker), 22 |
| klipper-02 | LXC 202 → ender3v2-02 | | 80, 7125, 22 |
| klipper-03 | LXC 203 → ender3v2-03 | | 80, 7125, 22 |

## USB port map

Physically label each host USB port. Record the `by-path` value — this is what goes into each
container's `lxc.mount.entry`.

| Label | Printer | `/dev/serial/by-path/...` |
|---|---|---|
| A | ender3v2-01 | |
| B | ender3v2-02 | |
| C | ender3v2-03 | |

**Do not use `/dev/serial/by-id/`.** The CH340 chips on these boards commonly report identical
(or absent) serial numbers, so all three printers can collide on one `by-id` name — the container
would silently attach to the wrong printer.

## Finding your LAN subnet

`printers/*/moonraker.conf` currently trusts all RFC1918 ranges (`192.168.0.0/16`, `10.0.0.0/8`,
`172.16.0.0/12`). That **works** on any home network without you knowing anything — it's the
Moonraker default. It's also broader than it needs to be: anything on your LAN can drive the
printers without a key.

To narrow it, find your actual subnet:

```bash
# on the Proxmox host, or any Linux box on the LAN
ip -4 addr show | grep inet
# -> inet 192.168.1.50/24  means your subnet is 192.168.1.0/24
```

macOS: `ipconfig getifaddr en0` then check the router. Windows: `ipconfig` → "IPv4 Address" and
"Subnet Mask" (255.255.255.0 = /24).

Then replace the three RFC1918 lines in each `moonraker.conf` with just your subnet, e.g.:

```
trusted_clients:
    192.168.1.0/24
    127.0.0.0/8
    ::1/128
```

Worth doing if you have guests, IoT devices, or roommates on the same network. Skippable if the
LAN is just you — the printers are not reachable from the internet either way.

## Access

Everything is LAN-only by design. If you later want remote access, use a VPN (WireGuard/Tailscale)
rather than port-forwarding Moonraker — Moonraker exposes an unauthenticated-by-default API that
can move a heated printer.
