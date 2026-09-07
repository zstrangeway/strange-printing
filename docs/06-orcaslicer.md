# OrcaSlicer setup

OrcaSlicer talks to Moonraker natively, so you slice once and push to whichever printer is free.

## Printer profile

**Add Printer → Creality → Ender-3 V2**, then override:

| Setting | Value | Why |
|---|---|---|
| G-code flavor | **Klipper** | Enables Klipper-specific macros and `SET_` commands |
| Bed shape | 235 x 235 | Stock V2 |
| Max print height | 250 | Stock V2 |
| Start G-code | see below | Must match your macros, not Marlin's |

Once flavor is Klipper, OrcaSlicer's stock Creality start G-code (which uses Marlin-isms) should
be replaced with a call into a Klipper macro. Keep the logic in `printer.cfg`, not in the slicer —
that way all three printers and every profile share one definition.

**Start G-code:**
```
START_PRINT EXTRUDER_TEMP=[nozzle_temperature_initial_layer] BED_TEMP=[bed_temperature_initial_layer_single_extruder]
```

**End G-code:**
```
END_PRINT
```

The matching `[gcode_macro START_PRINT]` / `END_PRINT` definitions are in
`printers/_template/printer.cfg`.

## Physical printers (one entry per machine)

**Printer settings → Connection**, or the "Physical Printer" dialog:

| Field | Value |
|---|---|
| Host Type | `Klipper (Moonraker)` |
| Hostname / IP | `http://192.168.1.201` (the **container** IP, not the Proxmox host) |
| API Key | leave blank if Moonraker trusts your LAN subnet; otherwise paste the key |

Repeat for `.202` and `.203`. Name them `ender3v2-01/02/03` to match this repo.

If OrcaSlicer reports "connection failed", check in this order:
1. Is Moonraker's `[authorization] trusted_clients` covering your workstation's subnet?
   (`printers/_template/moonraker.conf` has it.)
2. Is `cors_domains` allowing your slicer host?
3. Can you reach `http://<container-ip>:7125/printer/info` in a browser?

## Filament and process profiles

Keep these **shared across all three printers**, not per-printer. A print farm's value comes from
any job running on any machine; per-printer filament profiles quietly destroy that.

Machine-specific compensation (a printer that runs cool, one with a worn nozzle) belongs in that
printer's `printer.cfg` — e.g. a `[gcode_macro]` temperature offset — so the slicer profile stays
universal.

Export finished profiles to `docs/orcaslicer-profiles/` and commit them.

## Sending a job

Slice → **Print** (not Export) → pick the physical printer → uploads via the Moonraker API and
optionally starts immediately. Watch the first layer in Fluidd before walking away.
