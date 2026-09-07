# CLAUDE.md

Context for anyone (human or agent) picking this repo up cold.

## What this is

A workspace for building and running a 3-printer 3D print farm. **Documentation and config, not
an application.** There is nothing to build, no test suite, no CI. The deliverable is that three
printers reliably print.

## The build

| Thing | Detail |
|---|---|
| Printers | 3x Creality Ender 3 V2, **4.2.2** mainboards (TMC2208 standalone, CH340 USB-serial on USART1) |
| Probe | BLTouch/CR-Touch — **unconfirmed how many of the three have one**, see below |
| Host | Lenovo ThinkCentre M710s SFF, model `10M70030US`, Kaby Lake |
| Hypervisor | Proxmox VE, one unprivileged Debian 12 LXC per printer (CTID 201/202/203) |
| Printer stack | Klipper + Moonraker + Fluidd, installed via KIAUH |
| Slicer | OrcaSlicer, talking to Moonraker over the network |

## Decisions already made — don't relitigate without reason

- **One LXC per printer**, not one container with three Klipper instances. Isolation beats the
  ~200 MB saved.
- **Devices addressed by `/dev/serial/by-path`, never `by-id`.** The CH340 chips on 4.2.x boards
  commonly share or omit serial numbers; with three identical printers `by-id` can silently
  attach a container to the wrong machine. Each container binds exactly one device, presented
  internally at the fixed path `/dev/printer` — so every `printer.cfg` has an identical `[mcu]`
  line.
- **Print logic lives in Klipper macros** (`START_PRINT` / `END_PRINT` in `printer.cfg`), not in
  slicer start G-code. One slicer profile stays valid for all three machines.
- **Filament and process profiles are shared; machine profiles are per-printer.** Per-printer
  filament profiles destroy the point of a farm. Machine-specific compensation goes in that
  printer's `printer.cfg`.
- **Saved bed mesh, loaded per print** rather than probing every job.
- **Fluidd over Mainsail** — arbitrary, but be consistent.
- **`printer.cfg` files are self-contained**, not split into includes. One `scp` per printer.

## Source of truth

`printers/*/` is authoritative. The copies inside the containers are deployments.

Klipper's `SAVE_CONFIG` writes to the container, so **after any calibration, pull the config back
and commit it**:

```bash
scp root@<container-ip>:/home/klipper/printer_data/config/printer.cfg printers/ender3v2-01/
```

An uncommitted `SAVE_CONFIG` block is the thing that gets lost.

## Open questions (as of the last session)

1. **How many printers actually have a BLTouch?** All three configs currently assume one. A stock
   machine running the probe config drives its nozzle into the bed on the first `G28`. This is
   the highest-consequence open item.
2. **Probe X/Y offsets.** `-44 / -9` in the configs is the common Creality-mount value and a
   guess. Must be measured per machine.
3. **Does the M710s still have a spinning boot disk?** If so, fit an SSD before installing
   Proxmox — reinstalling later means rebuilding every container.
4. **LAN subnet** — `moonraker.conf` trusts all RFC1918 ranges. Works; narrower is better.

## Conventions

- Docs are numbered in the order you need them: `docs/00-plan.md` through `docs/09-`.
- Printer IDs are `ender3v2-01/02/03` everywhere — repo dirs, container hostnames, OrcaSlicer
  physical printer names. Keep them aligned.
- `printers/_template/` is the starting point for a new machine; per-printer dirs are copies that
  diverge as they're tuned.
- Nothing secret should ever land here. `.gitignore` covers keys, `.env`, and gcode.

## Working style for this repo

- Be concrete about hardware. Wrong pin numbers and wrong offsets damage physical machines.
- Mark guesses as guesses. Several values in `printer.cfg` are starting points that must be
  measured — they're commented as such and should stay that way until verified.
- Prefer editing the docs over answering in chat. Chat context does not survive; this repo does.
