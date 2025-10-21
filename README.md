# Simple Bootloader (16-bit BIOS, Floppy Image)

This is a **minimal x86 real-mode bootloader** that loads a tiny "OS" from the next sectors of the disk and jumps to it. It is intentionally small and educational.

## What it does
- `boot/boot.asm` is a 512‑byte boot sector.
- It prints `Booting tiny OS...`, loads 20 sectors starting at LBA 1 into memory at `0x1000:0000`, and far-jumps there.
- `kernel/kernel.asm` is a real‑mode program that prints a message and halts.

## Build
You need **NASM** and standard Unix tools.

```bash
# On macOS (Homebrew) or Linux
nasm -v

# Build
make
```

This produces `build/disk.img` (1.44MB floppy).

## Run (Fastest: QEMU)
```bash
make run
```

## Run in VMware Workstation / Fusion
1. Create a new VM (Other > Other/Unknown, BIOS firmware).
2. Add a **Floppy Drive** device and attach `build/disk.img`.
3. Ensure the VM boots from floppy first.
4. Power on. You should see:
   - `Booting tiny OS...`
   - `Hello from the tiny OS kernel!`

> **Note:** If your VM firmware is UEFI-only, enable Legacy/BIOS mode (CSM). This bootloader uses BIOS interrupts (INT 13h).

## Run in VirtualBox
- Create a VM (Other/Unknown 32-bit).
- Enable **Floppy** in Boot Order.
- Use `build/disk.img` as a Floppy Controller image.

## Project Layout
```
boot/
  boot.asm       ; 512B boot sector
kernel/
  kernel.asm     ; tiny real-mode "OS"
Makefile
README.md
```

## How it works (short)
- BIOS loads 512 bytes at `0x7C00` (the boot sector), sets `DL = boot drive`.
- We print a banner, then perform CHS reads via `INT 13h` to copy 20 sectors into memory at `0x1000:0000`.
- We `retf` to that address. The kernel prints text and halts.

## Extend it
- Increase the number of sectors to load (SI register) for larger kernels.
- Replace `kernel/kernel.asm` with a C or 32‑bit protected‑mode kernel.
- Add a simple filesystem parser (e.g., FAT12) to locate files instead of assuming a fixed LBA.

## Troubleshooting
- If you see `Disk read error`, the VM couldn't read sectors. Ensure the kernel is placed directly after the boot sector (our Makefile does this).
- If nothing prints: confirm the VM uses **BIOS** mode. UEFI VMs won't provide INT 10h/13h services by default.

Have fun hacking!
