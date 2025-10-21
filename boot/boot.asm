; boot/boot.asm - 512-byte boot sector (FAT12/MBR style) for BIOS VMs
; Builds with: nasm -f bin -o boot.bin boot.asm
; Loads 20 sectors (10 KiB) starting from LBA 1 (i.e., the sector right after the boot sector)
; into 0000:1000h (physical 0x10000), then jumps there.
; This expects that kernel.bin is placed immediately after the boot sector in the disk image.

BITS 16                ; Tell assembler we're working in 16-bit real mode
ORG 0x7C00            ; BIOS loads boot sector at memory address 0x7C00

start:
    cli               ; Clear Interrupt Flag - disable interrupts during setup
    xor ax, ax        ; Set AX register to 0 (XOR with itself = 0)
    mov ds, ax        ; Set Data Segment to 0 (DS = 0)
    mov es, ax        ; Set Extra Segment to 0 (ES = 0) 
    mov ss, ax        ; Set Stack Segment to 0 (SS = 0)
    mov sp, 0x7C00    ; Set Stack Pointer to 0x7C00 (stack grows downward from boot sector)
    sti               ; Set Interrupt Flag - re-enable interrupts

    ; Print a short message
    mov si, boot_msg      ; Load address of boot_msg string into SI (Source Index)
.print_char:              ; Local label for character printing loop
    lodsb                 ; Load byte from [DS:SI] into AL, then increment SI
    or al, al             ; Test if AL is zero (OR with itself sets flags)
    jz .after_print       ; Jump to .after_print if Zero Flag is set (end of string)
    mov ah, 0x0E          ; Set AH = 0x0E (BIOS function: write character in TTY mode)
    mov bx, 0x0007        ; BH = page number (0), BL = color attribute (7 = light gray)
    int 0x10              ; Call BIOS video interrupt to print character
    jmp .print_char       ; Jump back to start of loop for next character
.after_print:

    ; Set up read parameters
    mov bx, 0x1000        ; Load 0x1000 into BX
    mov es, bx            ; Set Extra Segment to 0x1000 (where we'll load kernel)
    xor bx, bx            ; Set BX offset to 0x0000 (so ES:BX = 0x1000:0000)
    mov dh, 0             ; Set head number to 0 (floppy has 2 heads: 0 and 1)
    mov dl, [BootDrive]   ; Load boot drive number saved by BIOS into DL
    ; We'll load 20 sectors starting from CHS(0,0,2)
    mov si, 20            ; Set counter: number of sectors to read (20 sectors = 10KB)

    ; Read loop using CHS, sector increments, track wraps after sector 18
    ; CHS addressing for 1.44MB floppy: 80 tracks, 2 heads, 18 sectors/track
    ; We'll assume floppy geometry for simplicity, which works fine in VMs for a 1.44MB img.
    mov bp, 2             ; Start at sector 2 (sector numbering starts at 1, sector 1 is boot sector)
    xor cx, cx            ; Clear CX register (CH = track number, initially 0)
    xor dx, dx            ; Clear DX register 
    mov dh, 0             ; Set head to 0 (redundant but explicit)

.read_next:               ; Main disk reading loop
    push cx               ; Save CX (track info) on stack
    push dx               ; Save DX (head/drive info) on stack  
    push bx               ; Save BX (memory offset) on stack
    mov ah, 0x02          ; Set AH = 0x02 (BIOS function: read sectors from disk)
    mov al, 1             ; Set AL = 1 (read 1 sector at a time)
    mov ch, cl            ; Move track number from CL to CH (CH = track low 8 bits)
    push bx               ; Save BX register temporarily
    mov bx, bp            ; Move sector number from BP to BX
    mov cl, bl            ; Move sector number to CL (low 6 bits of CL = sector)
    pop bx                ; Restore BX register
    ; CL format: bits 0-5 = sector (1-63), bits 6-7 = high 2 bits of track
    ; Our tracks fit in 0-79, so high bits are zero for this simple case
    int 0x13              ; Call BIOS disk interrupt to read sector
    jc .disk_error        ; Jump to error handler if Carry Flag is set (error occurred)

    pop bx                ; Restore BX (memory offset) from stack
    add bx, 512           ; Advance memory pointer by 512 bytes (1 sector size)
    jnc .no_carry         ; Jump if no carry occurred (didn't exceed 64KB boundary)
    ; If carry occurred, we crossed 64KB boundary, need to adjust segment
    mov dx, es            ; Move current Extra Segment value to DX
    add dx, 0x1000        ; Add 0x1000 to move to next 64KB segment (4096 paragraphs)
    mov es, dx            ; Store new segment value back to ES
.no_carry:

    ; increment CHS (Cylinder/Head/Sector addressing)
    inc bp                ; Increment sector number
    cmp bp, 19            ; Compare sector with 19 (sectors 1-18 exist on floppy)
    jne .next_ok          ; If not equal to 19, sector is valid, continue
    mov bp, 1             ; Reset sector to 1 (wrap around after sector 18)
    inc dh                ; Increment head number (0 -> 1)
    cmp dh, 2             ; Compare head with 2 (heads 0-1 exist on floppy)
    jne .next_ok          ; If not equal to 2, head is valid, continue  
    mov dh, 0             ; Reset head to 0 (wrap around after head 1)
    inc ch                ; Increment track/cylinder number
.next_ok:

    dec si                ; Decrement sector counter
    jnz .read_next        ; Jump back to read_next if not zero (more sectors to read)
    jmp .jump_kernel      ; All sectors read successfully, jump to kernel

.disk_error:
    ; print 'E' and hang
    mov si, err_msg       ; Load address of error message
.err_loop:                ; Error message printing loop
    lodsb                 ; Load byte from error message into AL, increment SI
    or al, al             ; Test if AL is zero (end of string)
    jz .hang              ; If zero, jump to hang (stop execution)
    mov ah, 0x0E          ; Set AH = 0x0E (BIOS function: write character)
    mov bx, 0x0004        ; Set color to red (BH=page 0, BL=red attribute)
    int 0x10              ; Call BIOS to print character
    jmp .err_loop         ; Continue printing error message

.hang:                    ; Infinite loop to stop execution
    cli                   ; Disable interrupts
.hlt_forever:             ; Halt loop
    hlt                   ; Halt processor (wait for interrupt)
    jmp .hlt_forever      ; Jump back to halt (in case of spurious interrupt)

.jump_kernel:
    ; Print debug message before jumping
    mov si, jump_msg      ; Load address of jump message
.print_jump:              ; Jump message printing loop
    lodsb                 ; Load byte from message into AL, increment SI
    or al, al             ; Test if AL is zero (end of string)
    jz .do_jump           ; If zero, proceed to jump
    mov ah, 0x0E          ; Set AH = 0x0E (BIOS function: write character)
    mov bx, 0x000A        ; Set color to green (BH=page 0, BL=green attribute)
    int 0x10              ; Call BIOS to print character
    jmp .print_jump       ; Continue printing message
.do_jump:
    ; Jump to loaded code at 0x1000:0000
    push word 0x1000      ; Push segment (0x1000) onto stack
    push word 0x0000      ; Push offset (0x0000) onto stack  
    retf                  ; Far return: pop offset and segment, jump to 0x1000:0000

boot_msg db "Booting tiny OS...", 0x0D,0x0A, 0    ; Boot message with carriage return, line feed, null terminator
jump_msg db "Jumping to kernel...", 0x0D,0x0A, 0  ; Jump message with carriage return, line feed, null terminator  
err_msg  db "Disk read error", 0                   ; Error message with null terminator

; BIOS sets this; we copy it from DL at entry. Keep at fixed place if needed.
BootDrive db 0        ; Storage for boot drive number (set by BIOS)

; Boot signature - BIOS looks for 0xAA55 at end of boot sector
times 510 - ($ - $$) db 0    ; Fill remaining space with zeros up to byte 510
dw 0xAA55                     ; Boot signature (0x55AA in little-endian format)
