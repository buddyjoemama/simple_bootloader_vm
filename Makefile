# Makefile - build a 1.44MB floppy image with a tiny bootloader and kernel
# Requirements: nasm, dd (or fallocate), truncate, python3 (for zip), and qemu-system-i386 for quick test
# Targets:
#   make            -> builds disk.img
#   make run        -> runs with QEMU (simplest)
#   make zip        -> creates simple_bootloader_vm.zip
#   make clean

NASM ?= nasm
QEMU ?= qemu-system-i386

BUILD := build
BOOT := boot
KERNEL := kernel

all: $(BUILD)/disk.img

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/boot.bin: $(BOOT)/boot.asm | $(BUILD)
	$(NASM) -f bin -o $@ $<

$(BUILD)/kernel.bin: $(KERNEL)/kernel.asm | $(BUILD)
	$(NASM) -f bin -o $@ $<

$(BUILD)/disk.img: $(BUILD)/boot.bin $(BUILD)/kernel.bin | $(BUILD)
	# Create a 1.44MB floppy image
	truncate -s 1474560 $@
	# Write boot sector (512 bytes) at LBA 0
	dd if=$(BUILD)/boot.bin of=$@ conv=notrunc bs=512 count=1
	# Place kernel immediately after boot sector
	dd if=$(BUILD)/kernel.bin of=$@ conv=notrunc bs=512 seek=1

run: all
	$(QEMU) -fda $(BUILD)/disk.img -boot a -m 64M

debug: all
	$(QEMU) -fda $(BUILD)/disk.img -boot a -m 64M -monitor stdio -d cpu_reset,int

test: all
	$(QEMU) -fda $(BUILD)/disk.img -boot a -m 64M -nographic

# Debug with GDB - starts QEMU with GDB server, waits for GDB to connect
debug-gdb: all
	@echo "Starting QEMU with GDB server..."
	@echo "In another terminal, run: make gdb-connect"
	@echo "Or manually: gdb -x .gdbinit"
	$(QEMU) -fda $(BUILD)/disk.img -boot a -m 64M -s -S

# Connect GDB to the running QEMU instance (run this in another terminal)
gdb-connect:
	gdb -x .gdbinit -ex "connect" -ex "bootstart"

# Alternative: step-by-step debugging from the start
debug-step: all
	@echo "Starting step-by-step debugging..."
	@echo "QEMU will pause at bootloader start (0x7c00)"
	@echo "Use GDB commands: stepi, next5, regs16, stepshow"
	$(QEMU) -fda $(BUILD)/disk.img -boot a -m 64M -s -S &
	sleep 1
	gdb -x .gdbinit -ex "connect" -ex "bootstart"

zip: all
	zip -r simple_bootloader_vm.zip . -x "build/*" "*.zip"

clean:
	rm -rf $(BUILD) *.zip

.PHONY: all run zip clean debug test debug-gdb gdb-connect debug-step
