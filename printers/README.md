# Printer configs

One directory per physical machine. `_template/` is the starting point.

```bash
cp -r printers/_template printers/ender3v2-01
```

These files are the **source of truth**. The copies inside the containers are deployments.
After any `SAVE_CONFIG` (PID tune, Z offset, probe calibration), pull the container's
`printer.cfg` back here and commit it — see `docs/08-runbook.md`.

What differs between printers, and what doesn't:

| Identical across all three | Per-printer |
|---|---|
| Pin map, kinematics, macros | PID values (both heaters) |
| `serial: /dev/printer` | Extruder `rotation_distance` |
| Slicer filament/process profiles | Z offset, endstop positions |
| | Input shaper frequencies |
| | Any mods (probe, direct drive) |
