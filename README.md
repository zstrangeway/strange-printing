# strange-printing

Workspace for building and running a small 3D print farm: **3x Creality Ender 3 V2** (4.2.2
mainboards, BLTouch), driven by **Klipper** instances hosted in **Proxmox LXC containers** on a
**Lenovo ThinkCentre M710s**, sliced with **OrcaSlicer**.

This repo is the source of truth for configuration, runbooks, and the state of the build.
It is documentation + config, not a deployable app.

## Target architecture

```
                    ┌─────────────────────────────────────────────┐
                    │  Proxmox VE host  (ThinkCentre M710s SFF)    │
                    │                                             │
   Workstation      │  ┌──────────────┐ ┌──────────────┐ ┌───────┐│
   ┌──────────┐     │  │ LXC 201      │ │ LXC 202      │ │ 203   ││
   │OrcaSlicer│─────┼─▶│ klipper      │ │ klipper      │ │ ...   ││
   │          │ HTTP│  │ moonraker    │ │ moonraker    │ │       ││
   └──────────┘     │  │ fluidd       │ │ fluidd       │ │       ││
                    │  └──────┬───────┘ └──────┬───────┘ └───┬───┘│
                    │         │ USB passthrough│             │    │
                    └─────────┼────────────────┼─────────────┼────┘
                              ▼                ▼             ▼
                          Ender 3 V2 #1    #2             #3
```

One LXC per printer. Each container is a self-contained Klipper + Moonraker + Fluidd stack
with exactly one USB device passed in. A printer dying, or a config mistake, takes down one
container instead of the farm.

## Repo layout

| Path | What's in it |
|---|---|
| `docs/` | Build guides and runbooks, numbered in the order you'll need them |
| `printers/` | Per-printer `printer.cfg` / `moonraker.conf` and machine-specific notes |
| `printers/_template/` | Starting point for a new machine |
| `scripts/` | Host-side helper scripts (container creation, stack bootstrap) |
| `slicer/` | Exported OrcaSlicer profiles, kept in sync across machines |

## Docs index

1. [`docs/01-hardware-inventory.md`](docs/01-hardware-inventory.md) — what we actually have; **fill this in first**
2. [`docs/02-proxmox-host.md`](docs/02-proxmox-host.md) — host install and prep
3. [`docs/03-klipper-lxc.md`](docs/03-klipper-lxc.md) — container creation + USB passthrough
4. [`docs/04-firmware.md`](docs/04-firmware.md) — building and flashing Klipper onto the Creality board
5. [`docs/05-first-run-calibration.md`](docs/05-first-run-calibration.md) — bring-up order per printer
6. [`docs/06-orcaslicer.md`](docs/06-orcaslicer.md) — slicer setup and sending jobs to Moonraker
7. [`docs/07-networking.md`](docs/07-networking.md) — IPs, ports, naming
8. [`docs/08-runbook.md`](docs/08-runbook.md) — day-to-day ops, backup, recovery
9. [`docs/09-power-and-layout.md`](docs/09-power-and-layout.md) — power budget, UPS, fire safety, physical layout

## Status

Nothing is built yet. See [`docs/00-plan.md`](docs/00-plan.md) for the checklist and open decisions.
