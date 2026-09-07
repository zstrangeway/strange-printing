# Hardware inventory

Fill this in before doing anything else. The board revision determines the Klipper build config,
and the mods determine `printer.cfg`.

## Printers

| ID | Serial / label | Mainboard rev | MCU | Extruder | Hotend | Bed probe | Notes |
|---|---|---|---|---|---|---|---|
| ender3v2-01 | | ? 4.2.2 / 4.2.7 | | stock Bowden? | stock? | none / BLTouch / CR-Touch | |
| ender3v2-02 | | | | | | | |
| ender3v2-03 | | | | | | | |

### How to find the mainboard revision

Power off, unplug, remove the bottom cover. The revision is silkscreened on the PCB
(`CREALITY 3D V4.2.2` or `V4.2.7`). It matters:

- **4.2.2** — TMC2208 drivers, standard step/dir
- **4.2.7** — TMC2225 drivers, **inverted direction pins** on some axes vs 4.2.2

Both are STM32F103 (or a GD32F303 clone, which builds identically). Both use the same
Klipper pin map for the Ender 3 V2 — see `docs/04-firmware.md`.

## Host

| Item | Value |
|---|---|
| Machine | |
| CPU / RAM / disk | |
| USB ports available | |
| Proxmox version | |
| Host IP | |

Sizing note: Klipper is not demanding. Three instances run comfortably in ~2 vCPU / 2 GB total.
Disk matters more than CPU — gcode uploads accumulate. 128 GB is plenty; 64 GB is workable.

## Consumables to check / replace

- [ ] Bowden PTFE tube (Capricorn if replacing) and pneumatic couplers
- [ ] Nozzles
- [ ] Belts and tensioners
- [ ] Bed springs (silicone spacers are a strict upgrade)
- [ ] Extruder arm (stock plastic arms crack — aluminum replacements are cheap)
- [ ] microSD card for each printer (needed for firmware flashing)
