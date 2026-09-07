# MCU firmware

All three printers are Creality 4.2.2, so this is **one build used three times**.

## What is and isn't automated

| Step | Automated? |
|---|---|
| Build options | Yes — `ender3v2-4.2.2.config`, committed |
| Cross-compiler install | Yes — `playbooks/firmware.yml` |
| Compile + fetch the binary | Yes — lands in `build/` with a date stamp |
| Writing it to a microSD | **No** — physical card |
| Power-cycling the printer to flash | **No** — physical |

```bash
cd ansible && ansible-playbook playbooks/firmware.yml
```

## Flashing (manual, per printer)

1. microSD formatted **FAT32, 4096-byte allocation unit**, nothing else on it.
2. Copy `build/firmware-4.2.2-<date>.bin` to the card under a name the board has
   **never seen before**. The stock bootloader silently refuses a repeated filename.
   The date stamp handles this as long as you don't reflash twice in one day —
   if you do, add a suffix.
3. Printer off → insert card → power on → wait ~10 s.
4. The DWIN screen stays dark. That's success, not failure.
5. Verify: Fluidd reports "Klipper ready".

Log every flash in that printer's `printers/ender3v2-XX/notes.md`.

## Verifying the config fragment

The fragment is trusted but not machine-verified. Once, on the first build, confirm
it against the interactive menu:

```bash
# in a container, as the klipper user
cd ~/klipper && make menuconfig     # compare against the resolved values
diff <(grep -E '^CONFIG_(MACH_STM32F103|STM32_FLASH_START|STM32_CLOCK_REF|STM32F103_SERIAL|SERIAL_BAUD)=' .config) -
```

`playbooks/firmware.yml` prints the resolved values on every run so a version bump
that renames a symbol is visible rather than silent.

## Host/MCU version lockstep

Klipper refuses to start if the host and MCU versions differ. When you update
Klipper on the containers, rebuild and reflash **all three** in the same sitting.
Pin `klipper_version` in `ansible/inventory/group_vars/printers.yml` to a tag if
you'd rather that never surprise you.
