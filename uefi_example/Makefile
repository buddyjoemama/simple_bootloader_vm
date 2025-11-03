# UEFI Bootloader Example Makefile
# Requires: gnu-efi library, gcc, ld, objcopy

# Compiler and tools
CC = gcc
LD = ld
OBJCOPY = objcopy

# Architecture (x86_64 for 64-bit UEFI)
ARCH = x86_64

# GNU-EFI paths - auto-detect platform
# Linux: /usr (from package manager)
# macOS: Not supported natively - use Docker (see build-macos.sh)
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    GNUEFI_DIR = /usr
else ifeq ($(UNAME_S),Darwin)
    $(error macOS detected! GNU-EFI requires ELF format. Use Docker: ./build-macos.sh)
endif

EFI_INC = $(GNUEFI_DIR)/include/efi
EFI_INC_ARCH = $(EFI_INC)/$(ARCH)
EFI_LIB = $(GNUEFI_DIR)/lib

# Compiler flags
# Note: -mno-red-zone is only valid on x86_64
CFLAGS = -I$(EFI_INC) \
         -I$(EFI_INC_ARCH) \
         -fno-stack-protector \
         -fpic \
         -fshort-wchar \
         -DEFI_FUNCTION_WRAPPER \
         -Wall \
         -Wextra

ifeq ($(ARCH),x86_64)
    CFLAGS += -mno-red-zone
endif

# Linker flags
LDFLAGS = -nostdlib \
          -znocombreloc \
          -T $(EFI_LIB)/elf_$(ARCH)_efi.lds \
          -shared \
          -Bsymbolic \
          -L$(EFI_LIB) \
          $(EFI_LIB)/crt0-efi-$(ARCH).o

# Libraries
LIBS = -lefi -lgnuefi

# Target
TARGET = bootx64.efi

# Object files
OBJS = main.o

# Default target
all: $(TARGET)

# Compile C to object file
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Link object file to shared object
main.so: $(OBJS)
	$(LD) $(LDFLAGS) $(OBJS) -o $@ $(LIBS)

# Convert shared object to EFI executable
$(TARGET): main.so
	$(OBJCOPY) -j .text \
	           -j .sdata \
	           -j .data \
	           -j .dynamic \
	           -j .dynsym \
	           -j .rel \
	           -j .rela \
	           -j .reloc \
	           --target=efi-app-$(ARCH) \
	           $< $@
	@echo ""
	@echo "Built: $(TARGET)"
	@echo ""

# Create FAT32 disk image with UEFI bootloader
disk.img: $(TARGET)
	@echo "Creating UEFI disk image..."
	# Create 50MB disk image
	dd if=/dev/zero of=disk.img bs=1M count=50 status=none
	# Format as FAT32
	mkfs.vfat -F 32 disk.img > /dev/null 2>&1 || \
		{ echo "Error: mkfs.vfat not found. Install dosfstools."; exit 1; }
	# Create EFI directory structure and copy bootloader
	mmd -i disk.img ::/EFI
	mmd -i disk.img ::/EFI/BOOT
	mcopy -i disk.img $(TARGET) ::/EFI/BOOT/BOOTX64.EFI
	@echo "Disk image created: disk.img"
	@echo ""

# Run in QEMU with UEFI firmware (OVMF)
# OVMF is an open-source UEFI firmware for virtual machines
run: disk.img
	@echo "Starting QEMU with UEFI firmware..."
	@echo "Note: This requires OVMF firmware to be installed."
	@echo ""
	@# Try to find OVMF firmware in common locations
	@if [ -f /opt/homebrew/share/qemu/edk2-x86_64-code.fd ]; then \
		qemu-system-x86_64 \
			-drive if=pflash,format=raw,readonly=on,file=/opt/homebrew/share/qemu/edk2-x86_64-code.fd \
			-drive format=raw,file=disk.img \
			-net none \
			-m 256M; \
	elif [ -f /usr/share/ovmf/OVMF.fd ]; then \
		qemu-system-x86_64 \
			-bios /usr/share/ovmf/OVMF.fd \
			-drive format=raw,file=disk.img \
			-net none \
			-m 256M; \
	elif [ -f /usr/share/edk2-ovmf/x64/OVMF.fd ]; then \
		qemu-system-x86_64 \
			-bios /usr/share/edk2-ovmf/x64/OVMF.fd \
			-drive format=raw,file=disk.img \
			-net none \
			-m 256M; \
	else \
		echo "ERROR: OVMF firmware not found!"; \
		echo ""; \
		echo "On macOS: brew install qemu"; \
		echo "On Ubuntu: sudo apt install ovmf"; \
		echo "On Arch: sudo pacman -S edk2-ovmf"; \
		echo ""; \
		exit 1; \
	fi

# Clean build artifacts
clean:
	rm -f $(OBJS) main.so $(TARGET) disk.img
	@echo "Cleaned build artifacts"

# Help target
help:
	@echo "UEFI Bootloader Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  make          - Build bootloader (.efi file)"
	@echo "  make disk.img - Create bootable UEFI disk image"
	@echo "  make run      - Build and run in QEMU"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make help     - Show this help"
	@echo ""
	@echo "Requirements:"
	@echo "  - gnu-efi library"
	@echo "  - gcc compiler"
	@echo "  - mtools (for FAT32 manipulation)"
	@echo "  - qemu-system-x86_64"
	@echo "  - OVMF firmware"
	@echo ""
	@echo "Installation (macOS):"
	@echo "  brew install gnu-efi qemu mtools"
	@echo ""
	@echo "Installation (Ubuntu/Debian):"
	@echo "  sudo apt install gnu-efi gcc binutils mtools qemu-system-x86 ovmf"
	@echo ""

.PHONY: all run clean help
