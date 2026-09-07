# Klipper firmware for the Creality 4.2.2 / 4.2.7 board

Klipper is two halves: the host process (`klippy`, in the LXC) and firmware on the printer's
mainboard. You build the firmware in the container and flash it via microSD.

## Build

Inside the container, as the `klipper` user:

```bash
cd ~/klipper
make menuconfig
```

Select **exactly** this for a stock Ender 3 V2 (4.2.2 or 4.2.7):

| Option | Value |
|---|---|
| Micro-controller Architecture | `STMicroelectronics STM32` |
| Processor model | `STM32F103` |
| Bootloader offset | `28KiB bootloader` |
| Clock Reference | `8 MHz crystal` |
| Communication interface | `Serial (on USART1 PA10/PA9)` |
| Baud rate | `250000` |

Notes:

- The USB port on these boards goes through a **CH340 chip wired to USART1** — it is *not* native
  USB. Selecting a USB interface produces firmware that never enumerates. This is the single most
  common flashing mistake on this board.
- Some later boards ship a **GD32F303** instead of the STM32F103. The above config works unchanged.
- Menu label wording drifts between Klipper versions ("28KiB bootloader" has historically also
  appeared as "27KiB"). Pick the bootloader offset entry that mentions the Creality/stock
  bootloader; if there's exactly one non-`no bootloader` option in the 24–32 KiB range, that's it.

```bash
make clean
make
```

Output: `~/klipper/out/klipper.bin`.

## Flash

The stock bootloader **refuses to reflash a file whose name it has already seen**. Every flash
needs a unique filename.

1. Format a microSD as **FAT32, 4096-byte allocation unit**, ≤ 8 GB if you have one. Larger or
   differently-formatted cards are the second most common flashing failure.
2. Copy `out/klipper.bin` to the card as `firmware-<printer>-<date>.bin`, e.g.
   `firmware-01-20260907.bin`. The card should contain nothing else.
3. Printer **off**. Insert card. Power on. Wait ~10 seconds.
4. The stock DWIN screen will stay dark or freeze. **This is success, not failure** — Klipper does
   not drive that display. Verify by checking whether the container sees the MCU.

```bash
# in the container
ls -l /dev/printer          # symlink/bind should exist
~/klippy-env/bin/python ~/klipper/scripts/whconsole.py 2>/dev/null || true
```

Real verification: restart Klipper from Fluidd. `Lost communication` / `mcu unknown` means the
flash didn't take; a clean "Klipper ready" means it did.

If it didn't take, in order of likelihood: filename already used, card format, wrong bootloader
offset, wrong communication interface.

## Record what you flashed

Log every flash in the printer's `notes.md` — date, Klipper git commit, build options. When one
printer misbehaves six months from now, this is the first thing you'll want.

```bash
cd ~/klipper && git rev-parse --short HEAD
```

## Keeping three boards in sync

Build once, flash the same `.bin` to all three (renaming per card). They're identical hardware.
Only rebuild when you update the host Klipper — **host and MCU versions must match**, and Klipper
will refuse to start with a clear error if they drift. Update all three at the same time.
