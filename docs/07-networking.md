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

## Access

Everything is LAN-only by design. If you later want remote access, use a VPN (WireGuard/Tailscale)
rather than port-forwarding Moonraker — Moonraker exposes an unauthenticated-by-default API that
can move a heated printer.
