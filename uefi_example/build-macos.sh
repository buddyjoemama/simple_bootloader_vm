#!/bin/bash
# Build script for macOS using Docker
# This script builds the UEFI bootloader inside a Linux container

set -e

echo "========================================="
echo "  UEFI Bootloader Builder (Docker)"
echo "========================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed!"
    echo ""
    echo "Install Docker Desktop:"
    echo "  brew install --cask docker"
    echo ""
    exit 1
fi

# Check if Docker daemon is running
if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running!"
    echo ""
    echo "Please start Docker Desktop and try again."
    echo ""
    exit 1
fi

echo "Building UEFI bootloader using Linux container..."
echo ""

# Build using Ubuntu container (force x86_64 platform)
docker run --rm \
    --platform linux/amd64 \
    -v "$(pwd):/work" \
    -w /work \
    ubuntu:22.04 \
    bash -c "
        # Update package lists
        apt-get update > /dev/null 2>&1 &&
        
        # Install build tools
        echo 'Installing build dependencies...' &&
        apt-get install -y gnu-efi gcc binutils mtools make > /dev/null 2>&1 &&
        
        # Update Makefile paths for Linux
        echo 'Configuring build...' &&
        sed -i 's|/opt/homebrew/Cellar/gnu-efi/3.0.18|/usr|g' Makefile &&
        sed -i 's|GNUEFI_DIR = /usr|GNUEFI_DIR = /usr|g' Makefile &&
        
        # Build
        echo 'Compiling UEFI application...' &&
        make clean > /dev/null 2>&1 || true &&
        make &&
        
        echo '' &&
        echo 'Build successful!' &&
        ls -lh bootx64.efi
    "

echo ""
echo "========================================="
echo "  Build Complete!"
echo "========================================="
echo ""
echo "The UEFI bootloader has been built:"
echo "  bootx64.efi"
echo ""
echo "To run it, you would need:"
echo "  1. Create a FAT32 disk image (make disk.img)"
echo "  2. Run QEMU with OVMF firmware"
echo ""
echo "However, running UEFI on macOS requires OVMF"
echo "firmware which is not easily available."
echo ""
echo "For actual testing, use the BIOS bootloader"
echo "in the parent directory instead:"
echo "  cd .. && make run"
echo ""
