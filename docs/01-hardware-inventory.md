# Hardware inventory

Fill this in before doing anything else. The board revision determines the Klipper build config,
and the mods determine `printer.cfg`.

## Printers

| ID | Serial / label | Mainboard rev | MCU | Extruder | Hotend | Bed probe | Notes |
|---|---|---|---|---|---|---|---|
| ender3v2-01 | | **4.2.2** | STM32F103 or GD32F303 | stock Bowden | stock | BLTouch? | |
| ender3v2-02 | | **4.2.2** | | stock Bowden | stock | BLTouch? | |
| ender3v2-03 | | **4.2.2** | | stock Bowden | stock | BLTouch? | |

**Confirmed:** all three are Creality **4.2.2** boards — TMC2208 drivers, one Klipper firmware
build covers all three.

**Open:** how many of the three actually have a BLTouch/CR-Touch fitted? The configs in
`printers/` currently assume **all three do**. If a machine is stock, switch its `[stepper_z]`
to block (B) in its `printer.cfg` and delete the `[bltouch]` / `[safe_z_home]` / `[bed_mesh]` /
`[screws_tilt_adjust]` sections. Getting this wrong crashes the nozzle into the bed on the
first `G28`, so verify per machine before homing.

### Board notes (4.2.2)

- TMC2208 drivers in standalone/legacy mode — **not** UART-configurable. There is no
  `[tmc2208]` section in `printer.cfg` and no sensorless homing. Microsteps and current are
  set by hardware.
- MCU is an STM32F103 or a GD32F303 clone. Both build identically under Klipper.
- The USB port is behind a **CH340** USB-serial chip wired to USART1 — not native USB. This
  drives both the firmware build options (`docs/04-firmware.md`) and the
  `by-path`-not-`by-id` rule (`docs/07-networking.md`).
- BLTouch/CR-Touch uses the 5-pin bed-level header: `PB0` control, `PB1` sensor.

## Host

| Item | Value |
|---|---|
| Machine | **Lenovo ThinkCentre M710s** (SFF), model `10M70030US` |
| CPU | 7th-gen Intel Core (Kaby Lake, LGA1151) — confirm exact SKU |
| RAM | 2x DDR4 SO-slots... **confirm**; likely 8 GB shipped |
| Disk | **confirm** — see the SSD note below |
| USB ports available | **count them**; needs 3 free rear ports |
| Proxmox version | |
| Host IP | |

### Verify the actual specs

Don't trust the model-number lookup. Boot a live USB or check BIOS, or after Proxmox is on:

```bash
lscpu | grep 'Model name'
free -h
lsblk -o NAME,SIZE,ROTA,MODEL      # ROTA=1 means spinning disk
lsusb -t                            # USB topology and controllers
```

### Sizing verdict

The M710s is **substantially more machine than this workload needs**. Three Klipper instances
total roughly 2 vCPU and 2 GB under load; a Kaby Lake i3 or better with 8 GB has ample headroom
for all three containers plus Proxmox itself.

Two things to actually check:

1. **Is the boot disk a spinning HDD?** Many M710s SKUs shipped with a 500 GB/1 TB 7200rpm
   drive. Proxmox on a HDD is genuinely unpleasant — slow container starts, and gcode uploads
   from OrcaSlicer will feel laggy. A cheap 250 GB SATA SSD is the single best money you can
   spend on this build. The M710s SFF has a 2.5" bay and, on most SKUs, an M.2 slot.
2. **8 GB is enough, but 16 GB is cheap.** DDR4 UDIMM for this generation is nearly free
   secondhand. Only worth it if you plan to add Spoolman, Obico, or camera streams later.

### USB port budget

Three printers = three USB-B cables into the back of the host. Verify you have three free
**rear** ports (front-panel ports work but leave cables draped across the case). All rear ports
hang off the same PCH controller, which is fine — the `by-path` addressing in
`docs/07-networking.md` distinguishes them by physical port regardless.

## Consumables to check / replace

- [ ] Bowden PTFE tube (Capricorn if replacing) and pneumatic couplers
- [ ] Nozzles
- [ ] Belts and tensioners
- [ ] Bed springs (silicone spacers are a strict upgrade)
- [ ] Extruder arm (stock plastic arms crack — aluminum replacements are cheap)
- [ ] microSD card for each printer (needed for firmware flashing)
