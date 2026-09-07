# ender3v2-01

## Identity

- Mainboard revision: 4.2.2
- MCU:
- Container: CTID / hostname / IP
- Host USB port label:
- Host `by-path`:

## Mods

| Date | Mod | Notes |
|---|---|---|
| | | |

## Firmware flashes

| Date | Klipper commit | Build options | Result |
|---|---|---|---|
| | | STM32F103 / 28KiB / 8MHz / USART1 / 250000 | |

## Calibration values

| Value | Result | Date |
|---|---|---|
| Probe fitted? (BLTouch / CR-Touch / none) | | |
| Probe x_offset / y_offset (measured) | | |
| Probe z_offset | | |
| Extruder rotation_distance | | |
| Extruder PID | | |
| Bed PID | | |
| Input shaper X / Y | | |

## Bring-up checklist

Tick as you go. Each machine gets its own copy of this list.

**Before Klipper**
- [ ] Runs on stock firmware: heats, homes, moves
- [ ] Screw terminals at PSU and bed connector checked — tight, no discolouration
- [ ] Belts tensioned, eccentric nuts adjusted, no wheel play
- [ ] PTFE tube and couplers inspected/replaced
- [ ] Extruder arm intact (stock plastic arms crack)

**Container**
- [ ] LXC created, USB device bound, `/dev/printer` present inside
- [ ] Klipper + Moonraker + Fluidd installed via KIAUH
- [ ] `printer.cfg` and `moonraker.conf` deployed from this repo

**Firmware**
- [ ] Built (STM32F103 / 28KiB / 8MHz / USART1 / 250000)
- [ ] Flashed with a unique filename
- [ ] Fluidd reports "Klipper ready"

**Bring-up (docs/05)**
- [ ] Thermistors read room temperature
- [ ] BLTouch responds to `BLTOUCH_DEBUG`, `QUERY_PROBE` toggles
- [ ] X/Y directions correct, endstops verified
- [ ] Probe X/Y offsets measured and set
- [ ] `G28` completes safely
- [ ] `SCREWS_TILT_CALCULATE` within tolerance
- [ ] `PROBE_CALIBRATE` done, z_offset saved
- [ ] `BED_MESH_CALIBRATE` done, `default` profile saved
- [ ] Extruder PID tuned
- [ ] Bed PID tuned
- [ ] `rotation_distance` verified with a 100 mm extrusion test
- [ ] 20 mm calibration cube within tolerance
- [ ] Benchy acceptable
- [ ] Tuned `printer.cfg` committed back to this repo

**Farm integration**
- [ ] Static IP / DHCP reservation set, recorded in `docs/07-networking.md`
- [ ] Added to OrcaSlicer as a physical printer
- [ ] Test job sliced and sent from OrcaSlicer end to end
- [ ] Included in the Proxmox `vzdump` schedule

## Quirks

Anything this specific machine does that the others don't.
