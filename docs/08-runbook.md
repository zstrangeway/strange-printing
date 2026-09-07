# Runbook

## Daily

- Fluidd dashboard per printer, or a single browser window with three tabs.
- Check filament before starting a long job. Runout sensors are not stock on the V2.

## Config changes

Configs live in **this repo** and are copied to containers — not the other way around.
Klipper's `SAVE_CONFIG` writes to the container, so after any calibration:

```bash
scp root@192.168.1.201:/home/klipper/printer_data/config/printer.cfg printers/ender3v2-01/
git add -A && git commit -m "ender3v2-01: <what changed>"
```

Do this immediately after tuning. An uncommitted `SAVE_CONFIG` block is the thing you'll lose.

## Updating Klipper

Host and MCU firmware versions must match. Update all three together:

1. In each container, KIAUH → **Update → Klipper**.
2. Rebuild firmware once (`make clean && make`), flash all three boards with uniquely-named files.
3. Verify each comes back with "Klipper ready" before printing.

## Backups

Two layers:

| Layer | What it protects | How |
|---|---|---|
| This repo | Configs — the part you can't recreate | `git push` after every change |
| `vzdump` | Whole containers — saves a rebuild | Proxmox → Datacenter → Backup, weekly |

## Common failures

| Symptom | Most likely cause |
|---|---|
| `Lost communication with MCU` mid-print | USB noise / cable. Reseat, shorten, add ferrite, check shared ground. |
| Klipper won't start after host update | MCU firmware version mismatch — reflash the board. |
| Container sees no `/dev/printer` | Printer powered off, or the host `by-path` changed because it was replugged into a different port. |
| Wrong printer responds | You used `by-id` somewhere. Switch to `by-path`. |
| Screen dark after flashing | Expected. Klipper doesn't drive the stock DWIN LCD. |
| First layer bad on one machine only | That printer's Z offset / bed level, not the slicer profile. |

## Rebuilding a printer from scratch

1. `pct create` from `scripts/create-klipper-lxc.sh`
2. Add the `lxc.mount.entry` for that printer's USB port
3. `scripts/bootstrap-klipper.sh` inside, then KIAUH
4. `scp` that printer's config from this repo
5. Reflash the board if the Klipper version moved

Roughly 30 minutes, most of it unattended.
