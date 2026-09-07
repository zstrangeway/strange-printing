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

## Where the build actually is

Established in the first session, worth not re-deriving:

- **Proxmox is already installed** on the M710s. No container has been created yet.
- **The mainboards already carry Klipper firmware** from a previous setup — an old version.
- **The Raspberry Pi hosts are gone.** There are no `printer.cfg` files to recover. Every
  calibration value in this repo is a starting point that has never been measured on these
  machines.
- Because host and MCU Klipper versions must match and there is no surviving host,
  **all three boards need reflashing** with a build matching whatever version the new
  containers run. `docs/04-firmware.md` applies.
- Printer 3 has **dual Z motors** (Y-splitter off the single Z driver on the 4.2.2 — there is no
  second Z driver, so this stays one `[stepper_z]`, no `[z_tilt]`, gantry levelled by hand) and
  **no BLTouch installed yet**, though one is on hand for it.
- Printers 1 and 2 have BLTouch fitted.

## Open questions

1. **Probe X/Y offsets.** `-44 / -9` is the common Creality-mount value and a guess. Measure per
   machine.
2. **Is the M710s boot disk spinning?** `lsblk -o NAME,SIZE,ROTA,MODEL`. Proxmox is already
   installed, so replacing it now means a reinstall — weigh it before building containers on top.
3. **LAN subnet** — `moonraker.conf` trusts all RFC1918 ranges. Works; narrower is better.

## What to do next

One printer, end to end, before touching the other two or writing any automation:

1. Create one LXC, pass through printer 1's USB device by `by-path`
2. Install Klipper + Moonraker + Fluidd (KIAUH is fine and fast; don't automate yet)
3. Build firmware in that container, flash printer 1 by SD card
4. Start from Klipper's own `config/printer-creality-ender3-v2-2020.cfg` in the checkout —
   **do not hand-write `printer.cfg` or the standard macros**, they ship working
5. Calibrate, commit the result, then repeat

## A note on the repo's current state

The first session overbuilt. `ansible/` is an untested Ansible tree written before a single
container existed; `76d64ae` is its commit and reverting that returns to the earlier static
docs. Several `docs/` pages still link to files that commit deleted, and `docs/10-iac.md` is
referenced but never written. Nothing here has run against hardware.

Fix or delete it as convenient — but don't treat it as working infrastructure, and don't extend
it before one printer prints.

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
