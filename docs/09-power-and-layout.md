# Power, layout, and unattended operation

The part of a print farm that isn't software. Worth getting right before three machines are
running jobs while you're asleep.

## Power budget

Per Ender 3 V2 (350 W / 24 V 15 A PSU):

| Load | Draw |
|---|---|
| Heated bed (235x235, 24 V) | ~250 W while heating |
| Hotend cartridge (40 W) | ~40 W |
| Steppers, fans, mainboard | ~30-50 W |
| **Peak, during bed warm-up** | **~280-300 W** |
| **Steady state, mid-print** | **~120-150 W** (bed cycles, doesn't run continuously) |

Farm totals:

| Scenario | Draw |
|---|---|
| 3 printers warming up simultaneously | ~900 W |
| 3 printers mid-print | ~400-450 W |
| ThinkCentre M710s (SFF, 65 W-class CPU, light load) | ~25-40 W |
| **Worst case, all three heating at once** | **~950 W** |

On a US 15 A / 120 V circuit (1800 W nominal, 1440 W continuous per the 80% rule) this fits with
room to spare — **as long as nothing else significant is on that circuit**. A space heater, a
shop vac, or a second farm is what puts you over.

Two practical notes:

- **Stagger warm-ups.** The 900 W spike only happens if you start three jobs in the same minute.
  Starting them a couple of minutes apart keeps the peak near 500 W. Not required, but free.
- **Measure, don't trust this table.** A $15 plug-in energy meter on the circuit tells you the
  real number in an afternoon. Bed heaters vary more than spec sheets suggest.

## What to put on a UPS

**The host, yes. The printers, no.**

- A power blip that reboots the Proxmox host corrupts nothing catastrophic, but you'd rather it
  shut down cleanly. A small UPS (even 350 VA) covers the M710s for the minutes needed.
- UPSing the printers is not worth it. A blip mid-print ruins the print regardless — a 1500 VA
  unit that would actually carry three heated beds costs more than a printer, and Klipper has no
  reliable power-loss resume. Let them fail.
- Configure Proxmox to shut down on low battery: install `nut` or `apcupsd` on the host and point
  it at the UPS over USB. Do this *after* the printers are running; it's not a bring-up blocker.

Everything on a decent surge protector regardless.

## Fire and unattended safety

Three ageing printers running unattended is the actual risk in this project, not a bad first
layer. Klipper helps more than stock Marlin here, but not by itself.

- **`verify_heater` is on by default** in Klipper and catches thermal runaway — a heater that
  isn't warming as commanded shuts the printer down. This is a real improvement over the stock
  Creality firmware. Do not disable or loosen it to "fix" a slow-heating bed; find the actual
  cause.
- **`max_temp` is a hard limit**, not a suggestion. The template sets 250 C hotend / 130 C bed.
  Leave them unless you've changed the hotend.
- **Check the mains-side wiring.** Creality's screw terminals at the PSU and the bed connector
  are a known weak point — loose or discoloured terminals are the documented failure mode. On
  printers that have been sitting, open the base and check every screw terminal is tight and
  nothing is browned. Do this once, now, on all three.
- **Smart plug per printer.** A WiFi/Zigbee plug per machine gives you a hard power cut from your
  phone that doesn't depend on Klipper being responsive. Moonraker can drive them directly via
  `[power]` sections, which also gives Fluidd an on/off button per printer.
- **Smoke detector in the room.** Not the same room as the one covering the rest of the house.
- **Hard surface, not carpet.** And nothing flammable within arm's reach of a bed.

### Optional: Moonraker power control

If you add smart plugs, in each container's `moonraker.conf`:

```
[power printer]
type: tplink              # or shelly, tasmota, homeassistant, gpio, ...
address: 192.168.1.x
locked_while_printing: True
off_when_shutdown: True
restart_delay: 3
```

`locked_while_printing` stops you from cutting power to a running job by accident.

## Physical layout

- **Keep USB runs under ~2 m.** This is the single biggest cause of `Lost communication with MCU`
  in USB-connected farms. Short, shielded, ferrite-cored cables. Don't bundle USB with mains.
- **Same circuit for host and printers.** Different circuits mean different ground references,
  which is how ground loops and random disconnects start.
- **Label everything.** Host USB port A/B/C, matching cable, matching printer, matching container.
  Recorded in `docs/07-networking.md`. When a printer drops off you want to know which cable to
  reseat without tracing.
- **Airflow and ambient temperature.** Three printers in a small enclosed room will raise ambient
  meaningfully. PLA warps less in warm air, PETG doesn't care, but the M710s will thank you for
  not sitting downstream of three beds.
- **Reachability.** You'll be pulling prints off three beds daily. Leave room to get a hand and a
  scraper in at the front of each machine.
