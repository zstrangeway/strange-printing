# Plan & open decisions

## Build order

- [ ] **Inventory** — record board revision, hotend/extruder mods, and PSU state for each printer (`docs/01-hardware-inventory.md`)
- [ ] **Bench-test each printer on stock firmware** — confirm it heats, homes, and moves *before* touching Klipper
- [ ] **Proxmox host** — install, network, storage, container template (`docs/02-proxmox-host.md`)
- [ ] **One printer end-to-end** — LXC 201, firmware flash, first print. Do not build 2 and 3 until 1 prints.
- [ ] **Clone the pattern** — LXC 202 / 203
- [ ] **OrcaSlicer** — printer profiles + physical-printer entries for all three
- [ ] **Ops** — config backup to this repo, host UPS/shutdown behavior, monitoring

## Open decisions

| Decision | Options | Leaning |
|---|---|---|
| Web UI | Fluidd / Mainsail | Fluidd — lighter, better on a multi-printer dashboard. Either is fine; pick one and stay consistent. |
| Container distro | Debian 12 / Ubuntu 24.04 | Debian 12 — KIAUH supports it, smaller footprint |
| Privileged vs unprivileged LXC | — | Unprivileged + explicit device passthrough. Privileged is easier but a worse default. |
| Slicer→printer path | Upload via Moonraker API / manual | Moonraker API from OrcaSlicer |
| Spoolman / Obico | Add later | Skip for initial bring-up |

## Known risks specific to this build

1. **CH340 serial numbers collide.** The USB-serial chip on Creality 4.2.x boards frequently reports no
   unique serial, so all three printers can show up under the *same* `/dev/serial/by-id/` name.
   Mitigation: address devices by `/dev/serial/by-path/` (stable per physical USB port) and label the
   ports physically. Covered in `docs/03-klipper-lxc.md`.
2. **USB noise / ground loops.** Printer-to-host USB runs in a farm are a common source of random
   disconnects (`Lost communication with MCU`). Keep runs short, use shielded cables with ferrites,
   and keep all printers and the host on the same circuit.
3. **The stock DWIN LCD does not work with Klipper.** After flashing, the screen is dead. That is
   expected, not a fault. Control is entirely via the web UI.
4. **Old, unmaintained printers.** These have been sitting. Belts, bed springs, Bowden couplers, and
   the PTFE tube are all consumables. Budget for replacements before blaming Klipper for bad prints.
5. **Single point of failure.** One host = all three printers down if it dies. Acceptable for a
   home farm; know that it's the tradeoff you're making versus a Pi per printer.
