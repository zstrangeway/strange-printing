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
| Host boot disk | keep HDD / add SSD | **Add an SSD** if the M710s still has its spinning drive — reinstalling later means rebuilding every container |
| Moonraker trusted_clients | all RFC1918 / just your subnet | Defaults work; narrow once the subnet is known (`docs/07-networking.md`) |
| Mesh per print | probe every job / load saved | Load saved. ~90 s/job back; re-probe on hardware changes only. |

## Known hardware (confirmed)

- **Mainboards:** all three are Creality **4.2.2** — TMC2208 standalone, one firmware build for
  all three, no `[tmc2208]` config sections, no sensorless homing.
- **Probe:** BLTouch/CR-Touch. Configs currently assume **all three** have one — confirm, because
  a stock machine running the probe config will crash its nozzle on first `G28`.
- **Host:** Lenovo ThinkCentre M710s SFF (`10M70030US`), Kaby Lake. Comfortably oversized for
  three Klipper instances.

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
6. **The probe is the Z endstop.** With `probe:z_virtual_endstop` there is no mechanical backstop —
   a BLTouch that fails to deploy sends the nozzle into the bed. Run the `BLTOUCH_DEBUG` checks in
   `docs/05` before the first `G28 Z` on every machine, and again after any rewiring.
