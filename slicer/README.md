# Slicer profiles

Exported OrcaSlicer profiles, committed so all three printers and any workstation stay in sync.

```
slicer/orcaslicer/
  machine/     one .json per physical printer (bed shape, gcode flavor, start/end gcode)
  filament/    shared across all printers — see below
  process/     shared across all printers — layer heights, speeds, walls
```

## The rule that matters

**Filament and process profiles are shared. Machine profiles are per-printer.**

The point of a farm is that any job runs on any machine. The moment you have
`PLA - printer 2` you've lost that. If one printer runs cool or under-extrudes, fix it in that
printer's `printer.cfg` (a temperature offset macro, a corrected `rotation_distance`) so the
slicer profile stays universal.

## Exporting

OrcaSlicer → **File → Export → Export Preset**, or copy from the config directory:

| OS | Path |
|---|---|
| Linux | `~/.config/OrcaSlicer/user/default/` |
| macOS | `~/Library/Application Support/OrcaSlicer/user/default/` |
| Windows | `%APPDATA%\OrcaSlicer\user\default\` |

Commit after any profile change you want to keep. These are the only copies that survive a
workstation rebuild.
