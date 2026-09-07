# First run & calibration (per printer)

Do this in order. Each step assumes the previous one passed. Do **not** run a print to test a
step that has its own test.

## 0. Safety check before the first move

With Klipper connected but before homing:

- `M112` (emergency stop) works from Fluidd — confirm the button is there and you know where it is.
- Thermistors read plausible room temperature. A reading of `-14 C` or `500 C` means a wrong
  `sensor_type` or a disconnected thermistor — fix before heating anything.
- **Keep a hand on the power switch for every first `G28`.** With the probe as Z endstop, a
  miswired or unconfigured BLTouch means nothing stops the nozzle.

### 0b. BLTouch check — do this BEFORE any Z homing

The probe is the Z endstop now. If it doesn't work, the nozzle drives into the bed.

```
BLTOUCH_DEBUG COMMAND=pin_down     ; pin extends
BLTOUCH_DEBUG COMMAND=pin_up       ; pin retracts
BLTOUCH_DEBUG COMMAND=self_test    ; pin cycles repeatedly; reset to stop
BLTOUCH_DEBUG COMMAND=reset
```

Then verify Klipper actually sees the trigger:

```
QUERY_PROBE                        ; -> probe: open
```
Push the pin up with a finger and re-run — it must report `probe: TRIGGERED`. If it doesn't,
stop. Do not home Z. Check the PB0/PB1 wiring on the 5-pin header.

A blinking BLTouch LED at power-on means an error state (usually the pin can't deploy, or a
wiring fault). It should self-test and go steady.

## 1. Check axis directions — one axis at a time

```
G91                    ; relative
G1 X10 F600            ; should move toward +X
```

If an axis moves the wrong way, invert its `dir_pin` in `printer.cfg` (add or remove the leading
`!`). Do this **before** homing: a reversed axis will drive into the endstop and grind.

## 2. Endstops

```
QUERY_ENDSTOPS         ; press X and Y switches by hand, re-run, confirm TRIGGERED changes
G28 X
G28 Y
```

Do **not** `G28 Z` until section 0b passed and section 5 is set up. With `probe:z_virtual_endstop`
the stock Z limit switch is no longer wired into anything.

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

## 5. Probe offsets, bed level, Z offset

Order matters here. Do all four, in order.

### 5a. Measure the probe's X/Y offset

The `x_offset: -44 / y_offset: -9` in the template is a **guess based on the common Creality
mount**. Measure yours:

- With the printer off, measure horizontally from the nozzle tip to the centre of the probe pin.
- Probe to the **left** of the nozzle → negative `x_offset`. Probe **toward the front** →
  negative `y_offset`.
- A few mm of error here shows up as a mesh that doesn't match the bed. Get it within ~1 mm.

If you change the offsets, re-check `[safe_z_home] home_xy_position` and `[bed_mesh] mesh_max`
so the probe still lands on the bed at every point.

### 5b. Mechanically level the bed first

A probe compensates for a bad bed; it doesn't fix one. Level the knobs first:

```
G28
SCREWS_TILT_CALCULATE
```

Klipper prints per-screw instructions like `front left : 01:30 CW`. Adjust, re-run, repeat until
all four read within ~5 minutes of the target. This is much faster and more accurate than paper.

### 5c. Probe Z offset

```
G28
PROBE_CALIBRATE
```
Then jog down with `TESTZ Z=-1`, `TESTZ Z=-0.1`, `TESTZ Z=+0.02` until a sheet of paper drags
slightly under the nozzle. Then:
```
ACCEPT
SAVE_CONFIG
```

Fine-tune during a first layer with `SET_GCODE_OFFSET Z_ADJUST=-0.01 MOVE=1`, then
`Z_OFFSET_APPLY_PROBE` + `SAVE_CONFIG` to make it permanent.

### 5d. Bed mesh

```
G28
BED_MESH_CALIBRATE
SAVE_CONFIG
```
This saves a `default` profile, which `START_PRINT` loads on every job. Re-run it after any
bed, spring, or build-sheet change — not before every print.

> If a machine turns out to be **stock (no probe)**: switch its `[stepper_z]` to block (B) in
> `printer.cfg`, delete the `[bltouch]`/`[safe_z_home]`/`[bed_mesh]`/`[screws_tilt_adjust]`
> sections, drop the `BED_MESH_PROFILE LOAD` line from `START_PRINT`, then level with paper and
> use `Z_OFFSET_APPLY_ENDSTOP` instead of `Z_OFFSET_APPLY_PROBE`.

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
