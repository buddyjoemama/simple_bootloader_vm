# UEFI on macOS - Quick Start

## TL;DR

**UEFI development on macOS requires Docker or a Linux VM** because GNU-EFI produces ELF binaries (Linux format), but macOS uses Mach-O format.

## Option 1: Use Docker (Easiest)

If you have Docker installed:

```bash
./build-macos.sh
```

This builds the UEFI bootloader inside a Linux container.

## Option 2: Just Read the Code

The code in `main.c` is educational and well-commented. You can:
- Read and understand UEFI concepts
- Compare with the BIOS example in `../boot/` and `../kernel/`
- See the differences between BIOS and UEFI approaches

## Option 3: Use the BIOS Example Instead

For actually running and testing bootloader code on macOS:

```bash
cd ..
make run
```

The BIOS example works perfectly on macOS because:
- NASM produces flat binary files (no object format issues)
- QEMU can run BIOS code without special firmware
- Simpler build process, fewer dependencies

## What You're Missing

The UEFI example demonstrates:
- Modern 64-bit boot environment
- C programming vs assembly
- Rich UEFI APIs (Graphics Output Protocol, etc.)
- Professional bootloader structure

But the core concepts (loading code, displaying graphics, handling input) are the same as the BIOS example.

## Installing Docker

If you want to try the Docker approach:

```bash
# Install Docker Desktop
brew install --cask docker

# Start Docker Desktop app
open -a Docker

# Wait for it to start, then run:
./build-macos.sh
```

## Summary

| Approach | Pros | Cons |
|----------|------|------|
| **Docker** | Can build UEFI code | Requires Docker, slower |
| **Linux VM** | Full Linux environment | Requires VM setup |
| **BIOS Example** | Works natively on macOS | "Old" technology |

**Recommendation**: Stick with the BIOS example for learning. It teaches the same concepts with less tooling complexity.
