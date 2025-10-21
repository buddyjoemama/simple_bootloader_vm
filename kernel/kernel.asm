; kernel/kernel.asm - a tiny real-mode "OS" with VGA text mode video driver
; It prints a banner using direct video memory access and loops.
; Loaded at 0x1000:0000 by bootloader

BITS 16               ; Tell assembler we're working in 16-bit real mode
ORG 0x0000           ; Code is positioned at offset 0 within the segment

; VGA Text Mode Constants
VIDEO_MEMORY equ 0xB800    ; VGA text mode video memory segment
SCREEN_WIDTH equ 80        ; 80 characters per line
SCREEN_HEIGHT equ 25       ; 25 lines total
WHITE_ON_BLACK equ 0x0F    ; White text on black background
GREEN_ON_BLACK equ 0x0A    ; Green text on black background
RED_ON_BLACK equ 0x0C      ; Red text on black background
BLUE_ON_BLACK equ 0x09     ; Blue text on black background

start:
    cli               ; Clear Interrupt Flag - disable interrupts during setup
    ; Set up segments for kernel loaded at 0x1000:0000
    mov ax, 0x1000    ; Load 0x1000 into AX register
    mov ds, ax        ; Set Data Segment to 0x1000 (where our kernel is loaded)
    mov ss, ax        ; Set Stack Segment to 0x1000  
    mov sp, 0x9000    ; Set Stack Pointer to 0x9000 (stack grows downward)
    
    ; Clear screen using video driver
    call clear_screen
    
    ; Set cursor position to top-left
    mov word [cursor_pos], 0
    
    sti               ; Set Interrupt Flag - re-enable interrupts

    ; Print kernel banner using video driver
    mov si, msg1          ; Load address of first message
    mov bl, GREEN_ON_BLACK ; Set color to green on black
    call print_string     ; Print first message
    
    mov si, msg2          ; Load address of second message  
    mov bl, WHITE_ON_BLACK ; Set color to white on black
    call print_string     ; Print second message
    
    mov si, msg3          ; Load address of third message
    mov bl, BLUE_ON_BLACK ; Set color to blue on black  
    call print_string     ; Print third message

.hang:                    ; Infinite loop to keep kernel running
    hlt                   ; Halt processor (wait for interrupt, saves power)
    jmp .hang             ; Jump back to halt (continue after any interrupt)

;==============================================================================
; VIDEO DRIVER FUNCTIONS
;==============================================================================

; Clear screen by filling video memory with spaces
clear_screen:
    push ax
    push cx
    push di
    push es
    
    mov ax, VIDEO_MEMORY  ; Point ES to video memory
    mov es, ax
    xor di, di           ; Start at beginning of screen (offset 0)
    mov ax, 0x0F20       ; Space character (0x20) + white on black attribute (0x0F)
    mov cx, SCREEN_WIDTH * SCREEN_HEIGHT  ; 80 * 25 = 2000 characters
    rep stosw            ; Fill screen with spaces
    
    pop es
    pop di  
    pop cx
    pop ax
    ret

; Print string with color
; Input: SI = string address, BL = color attribute
print_string:
    push ax
    push cx
    push di
    push es
    push si
    
    mov ax, VIDEO_MEMORY  ; Point ES to video memory
    mov es, ax
    
.print_loop:
    lodsb                ; Load character from string into AL
    or al, al            ; Test for null terminator
    jz .print_done       ; If null, we're done
    
    cmp al, 0x0A         ; Check for line feed (newline)
    je .newline          ; Handle newline
    cmp al, 0x0D         ; Check for carriage return  
    je .print_loop       ; Ignore carriage return, continue
    
    ; Calculate video memory position: DI = (row * 80 + col) * 2
    mov di, [cursor_pos] ; Get current cursor position
    shl di, 1            ; Multiply by 2 (each character takes 2 bytes)
    
    ; Store character and attribute to video memory
    mov [es:di], al      ; Store character
    mov [es:di+1], bl    ; Store color attribute
    
    ; Advance cursor
    inc word [cursor_pos]
    
    ; Check if we need to wrap to next line
    mov ax, [cursor_pos]
    mov dx, 0
    mov cx, SCREEN_WIDTH
    div cx               ; AX = row, DX = column
    cmp dx, 0            ; If column = 0, we wrapped
    jne .print_loop      ; Continue if no wrap
    
    ; Handle screen scrolling if needed
    cmp ax, SCREEN_HEIGHT
    jl .print_loop       ; Continue if not at bottom
    mov word [cursor_pos], (SCREEN_HEIGHT-1) * SCREEN_WIDTH  ; Move to last line
    jmp .print_loop
    
.newline:
    ; Move to beginning of next line
    mov ax, [cursor_pos]
    mov dx, 0
    mov cx, SCREEN_WIDTH  
    div cx               ; AX = current row, DX = current column
    inc ax               ; Move to next row
    mul cx               ; AX = next row * 80
    mov [cursor_pos], ax ; Update cursor position
    jmp .print_loop
    
.print_done:
    pop si
    pop es
    pop di
    pop cx
    pop ax
    ret

;==============================================================================
; DATA SECTION
;==============================================================================

cursor_pos dw 0          ; Current cursor position (0-1999 for 80x25 screen)

; Message strings (no need for CR/LF - we handle newlines directly)
msg1 db "Hello from the tiny OS kernel!", 0x0A, 0
msg2 db "Video driver loaded successfully!", 0x0A, 0  
msg3 db "Simple text-mode kernel is running!", 0x0A, 0