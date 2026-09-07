# First run & calibration (per printer)

Do this in order. Each step assumes the previous one passed. Do **not** run a print to test a
step that has its own test.

## 0. Safety check before the first move

With Klipper connected but before homing:

- `M112` (emergency stop) works from Fluidd — confirm the button is there and you know where it is.
- Thermistors read plausible room temperature. A reading of `-14 C` or `500 C` means a wrong
  `sensor_type` or a disconnected thermistor — fix before heating anything.

## 1. Check axis directions — one axis at a time

```
G91                    ; relative
G1 X10 F600            ; should move toward +X
```

If an axis moves the wrong way, invert its `dir_pin` in `printer.cfg` (add or remove the leading
`!`). Do this **before** homing: a reversed axis will drive into the endstop and grind.

## 2. Endstops

```
QUERY_ENDSTOPS         ; press each switch by hand, re-run, confirm TRIGGERED changes
G28 X
G28 Y
G28 Z                  ; nozzle over the bed, hand on the power switch
```

## 3. PID tune both heaters

The values in the template config are generic. Tune per printer:

```
PID_CALIBRATE HEATER=extruder TARGET=210
PID_CALIBRATE HEATER=heater_bed TARGET=60
SAVE_CONFIG
```

`SAVE_CONFIG` restarts Klipper and writes results to the bottom of `printer.cfg`. Copy the
resulting block back into this repo.

## 4. Extruder rotation_distance (E-steps)

Stock Ender 3 V2 extruder: `rotation_distance: 34.406`. Verify it — worn stock extruders
under-extrude.

1. Heat to 200 C. Mark the filament 120 mm above the extruder inlet.
2. `G91` then `G1 E100 F60`.
3. Measure remaining distance to the inlet. Should be 20 mm.
4. New value = `old_rotation_distance * actual_extruded / 100`.

## 5. Bed level and Z offset

Stock (no probe): mesh is manual. Level the four corners with paper, then
`Z_OFFSET_APPLY_ENDSTOP` after a first-layer test.

With a BLTouch/CR-Touch: add the `[bltouch]` and `[bed_mesh]` sections (commented in the
template), then `PROBE_CALIBRATE` → `TESTZ` → `ACCEPT` → `SAVE_CONFIG`, then `BED_MESH_CALIBRATE`.

## 6. Input shaper (optional but worth it)

Even without an accelerometer, ringing-tower test prints get you most of the way:

```
SET_VELOCITY_LIMIT ACCEL=... 
TUNING_TOWER COMMAND=SET_VELOCITY_LIMIT PARAMETER=ACCEL START=1500 FACTOR=500
```

Print `docs/assets/ringing_tower.stl` (from the Klipper repo). Measure, then set
`[input_shaper]` accordingly.

## 7. First real print

A 20 mm calibration cube. Measure X/Y/Z with calipers. Then a Benchy for overhangs and retraction.

## 8. Commit the tuned config

```bash
scp root@<container-ip>:/home/klipper/printer_data/config/printer.cfg printers/ender3v2-01/
git add printers/ender3v2-01/ && git commit -m "ender3v2-01: tuned PID and Z offset"
```
