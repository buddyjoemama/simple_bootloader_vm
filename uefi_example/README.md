# UEFI Bootloader Example

This directory contains a simple UEFI bootloader written in C using the GNU-EFI library.

## What is UEFI?

UEFI (Unified Extensible Firmware Interface) is the modern replacement for the legacy BIOS firmware. It's the standard firmware interface on all modern PCs, Macs, and servers.

## Key Differences: UEFI vs BIOS

| Feature | BIOS | UEFI |
|---------|------|------|
| **Architecture** | 16-bit real mode | 64-bit long mode |
| **Language** | Assembly required | C/C++ supported |
| **Boot Format** | 512-byte boot sector | PE32+ executable (.efi) |
| **Load Address** | 0x7C00 (fixed) | Dynamic allocation |
| **File System** | Raw sectors | FAT32, exFAT |
| **Graphics** | VGA BIOS (320x200) | GOP (any resolution) |
| **Disk Access** | INT 0x13 (CHS/LBA) | Block I/O Protocol |
| **Memory** | 1MB limit | Full 64-bit space |
| **APIs** | BIOS interrupts | Rich protocol interfaces |

## Features of This Example

This bootloader demonstrates:

1. **Console Output** - Text display using ConOut protocol
2. **System Information** - Query firmware version and specs
3. **Graphics** - Access Graphics Output Protocol (GOP) for modern display
4. **Memory Management** - Query UEFI memory map
5. **Interactive Menu** - Read keyboard input
6. **Rectangle Drawing** - Simple graphics demo (like the BIOS version)

## Architecture Overview

```
UEFI Firmware (OVMF in QEMU)
    │
    ├─> Loads EFI/BOOT/BOOTX64.EFI from FAT32 partition
    │
    ├─> Allocates memory for image
    │
    ├─> Calls efi_main(ImageHandle, SystemTable)
    │       │
    │       ├─> SystemTable->ConOut (console output)
    │       ├─> SystemTable->BootServices (memory, protocols)
    │       └─> SystemTable->RuntimeServices (time, variables)
    │
    └─> Application returns EFI_SUCCESS
```

## Build Requirements

### ⚠️ Important Note for macOS Users

GNU-EFI does not build natively on macOS because it requires ELF object format (macOS uses Mach-O). You have three options:

**Option 1: Use Docker (Recommended)**
```bash
# Install Docker Desktop for Mac
brew install --cask docker

# Build and run using Linux container (see Docker section below)
```

**Option 2: Use a Linux VM**
- Install VirtualBox or VMware
- Create Ubuntu/Fedora VM
- Install build tools inside VM

**Option 3: Cross-compile (Advanced)**
- Build an ELF-targeting cross-compiler toolchain
- Complex setup, not recommended for learning

### Ubuntu/Debian (Native or in Docker)
```bash
sudo apt install gnu-efi gcc binutils mtools qemu-system-x86 ovmf
```

### Arch Linux
```bash
sudo pacman -S gnu-efi gcc binutils mtools qemu edk2-ovmf
```

## Building and Running

### On Linux (Native)
```bash
# Build the bootloader
make

# Create disk image and run in QEMU
make run

# Clean build artifacts
make clean

# Show help
make help
```

### On macOS (Using Docker)
```bash
# Build using Docker container
docker run --rm -v $(pwd):/work -w /work ubuntu:22.04 bash -c "
  apt-get update && 
  apt-get install -y gnu-efi gcc binutils mtools make &&
  make
"

# Run with QEMU (if you have qemu installed via Homebrew)
# Note: This won't work without OVMF firmware
# Instead, just view the generated .efi file as proof of build
ls -lh bootx64.efi
```

For **macOS users**, the easiest way to actually **run** UEFI code is to use the BIOS bootloader example in the parent directory instead. UEFI development on macOS requires either Docker, a Linux VM, or complex cross-compilation setup.

## File Structure

```
uefi_example/
├── main.c          - UEFI application source code
├── Makefile        - Build system
└── README.md       - This file
```

## How It Works

### 1. Compilation
The C source is compiled with special flags for UEFI:
- `-fpic` - Position independent code
- `-fno-stack-protector` - No stack canaries
- `-fshort-wchar` - Wide characters are 2 bytes
- `-mno-red-zone` - Don't use red zone (required for UEFI)

### 2. Linking
The object file is linked with GNU-EFI runtime (`crt0-efi-x86_64.o`) and libraries to create a shared object.

### 3. Conversion
`objcopy` converts the shared object to PE32+ format (.efi), which UEFI firmware can load.

### 4. Disk Image
The .efi file is placed at `EFI/BOOT/BOOTX64.EFI` on a FAT32 partition. This is the standard location UEFI looks for a bootloader.

### 5. QEMU Execution
QEMU loads OVMF (open-source UEFI firmware), which then loads our bootloader from the disk image.

## Key UEFI Concepts

### System Table
The main entry point to all UEFI services:
```c
EFI_SYSTEM_TABLE *SystemTable
    ├─> ConOut              - Console output
    ├─> ConIn               - Console input
    ├─> BootServices        - Boot-time services
    └─> RuntimeServices     - Runtime services
```

### Boot Services (available before ExitBootServices)
- Memory allocation
- Protocol location
- Event handling
- Image management

### Runtime Services (available always)
- Time services
- Variable storage
- Firmware updates
- Reset/shutdown

### Protocols
UEFI uses protocols for device access:
- **Graphics Output Protocol (GOP)** - Modern framebuffer access
- **Simple File System Protocol** - File I/O
- **Block I/O Protocol** - Disk access
- **Simple Text Input/Output** - Console
- Many more...

## Graphics: VGA (BIOS) vs GOP (UEFI)

| Feature | VGA Mode 13h | GOP |
|---------|--------------|-----|
| Resolution | 320x200 fixed | Any resolution |
| Colors | 256 (indexed) | 16.7M (RGB) |
| Address | 0xA0000 fixed | Dynamic buffer |
| Pixel Format | 1 byte/pixel | 4 bytes/pixel (BGRA) |
| Access | Direct writes | Blt() function |

### Drawing in UEFI
```c
// BIOS way (direct memory access)
char *vga = (char*)0xA0000;
vga[y * 320 + x] = color;  // 1 byte per pixel

// UEFI way (GOP protocol)
EFI_GRAPHICS_OUTPUT_BLT_PIXEL pixel = {R, G, B, 0};
gop->Blt(gop, &pixel, EfiBltVideoFill, 0, 0, x, y, w, h, 0);
```

## Debugging Tips

1. **QEMU Serial Output**: Add `-serial stdio` to see debug messages
2. **UEFI Shell**: OVMF includes a shell - you can manually run bootloader
3. **GDB**: Add `-s -S` to QEMU, then `gdb bootx64.efi` and `target remote :1234`

## Common Issues

### "OVMF firmware not found"
Install OVMF firmware for your platform (see Build Requirements).

### "gnu-efi headers not found"
The Makefile assumes Homebrew installation on macOS. Adjust `GNUEFI_DIR` if installed elsewhere.

### "mkfs.vfat not found"
Install mtools package for FAT32 utilities.

## Next Steps

After understanding this example:

1. **Load a kernel** - Use LoadImage/StartImage to chain-load another EFI app
2. **File System** - Use Simple File System Protocol to read files
3. **Graphics** - Draw more complex graphics with GOP
4. **Memory Maps** - Parse and use UEFI memory descriptors
5. **Exit Boot Services** - Transition to OS mode and take over hardware

## Resources

- [UEFI Specification](https://uefi.org/specifications)
- [GNU-EFI Library](https://sourceforge.net/projects/gnu-efi/)
- [OVMF (Open Virtual Machine Firmware)](https://github.com/tianocore/edk2)
- [OSDev Wiki - UEFI](https://wiki.osdev.org/UEFI)

## Comparison with BIOS Example

This UEFI example is equivalent to the BIOS bootloader in `boot/` and `kernel/` directories, but:

- **More code** - UEFI requires more boilerplate
- **Easier development** - C instead of assembly
- **Better APIs** - Rich protocols instead of BIOS interrupts
- **Modern hardware** - Full access to 64-bit, multiple cores, large memory
- **More complex build** - Requires gnu-efi, specific linker scripts, PE32+ conversion
- **Platform-specific** - Harder to build on macOS due to object format differences

Both draw a red rectangle on screen - but UEFI does it in a much more sophisticated way!

## Why UEFI Development on macOS is Difficult

GNU-EFI and other UEFI toolchains produce **ELF** object files (Linux format), but macOS uses **Mach-O** format. The compiler and linker on macOS don't support ELF output without a cross-compilation toolchain.

Solutions:
1. **Docker** - Build inside Linux container (see `build-macos.sh`)
2. **Linux VM** - Use VirtualBox/VMware with Ubuntu
3. **Stick with BIOS** - The example in `../boot/` and `../kernel/` works perfectly on macOS

For learning purposes, the BIOS example is actually better - it's simpler, requires less infrastructure, and teaches the fundamentals.
