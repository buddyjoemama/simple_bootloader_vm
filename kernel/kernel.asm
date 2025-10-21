; kernel/kernel.asm - a tiny real-mode "OS"
; It prints a banner, shows basic info, and loops.
; Loaded at 0x1000:0000 by bootloader

BITS 16               ; Tell assembler we're working in 16-bit real mode
ORG 0x0000           ; Code is positioned at offset 0 within the segment

start:
    cli               ; Clear Interrupt Flag - disable interrupts during setup
    ; Set up segments for kernel loaded at 0x1000:0000
    mov ax, 0x1000    ; Load 0x1000 into AX register
    mov ds, ax        ; Set Data Segment to 0x1000 (where our kernel is loaded)
    mov es, ax        ; Set Extra Segment to 0x1000
    mov ss, ax        ; Set Stack Segment to 0x1000  
    mov sp, 0x9000    ; Set Stack Pointer to 0x9000 (stack grows downward)
    sti               ; Set Interrupt Flag - re-enable interrupts

    mov si, msg           ; Load address of message string into SI (Source Index)
.print:                   ; Local label for character printing loop
    lodsb                 ; Load byte from [DS:SI] into AL register, then increment SI
    or al, al             ; Test if AL is zero by ORing with itself (sets flags)
    jz .after             ; Jump to .after if Zero Flag is set (end of string reached)
    mov ah, 0x0E          ; Set AH = 0x0E (BIOS function: write character in TTY mode)
    mov bx, 0x000F        ; BH = page number (0), BL = color attribute (15 = bright white)
    int 0x10              ; Call BIOS video interrupt 0x10 to print character
    jmp .print            ; Jump back to start of loop for next character
.after:

.hang:                    ; Infinite loop to keep kernel running
    hlt                   ; Halt processor (wait for interrupt, saves power)
    jmp .hang             ; Jump back to halt (continue after any interrupt)

; Message string with formatting
msg db 0x0D,0x0A,"Hello from the tiny OS kernel!",0x0D,0x0A           ; Carriage return, line feed, message, CR, LF
    db "If you can read this, the bootloader loaded me from disk :)",0x0D,0x0A,0  ; Second line with null terminator
; 0x0D = Carriage Return (CR), 0x0A = Line Feed (LF), 0 = null terminator
