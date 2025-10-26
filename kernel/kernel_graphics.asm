; kernel/kernel_graphics.asm - Draw a red square in the center
BITS 16
ORG 0x0000

start:
    cli
    mov ax, 0x1000
    mov ds, ax
    mov ss, ax
    mov sp, 0x9000
    sti

    ; Switch to graphics mode
    mov ah, 0x00
    mov al, 0x13
    int 0x10

    ; Set ES to graphics memory
    mov ax, 0xA000
    mov es, ax

    ; Clear screen to black
    xor di, di
    xor al, al          ; Black color
    mov cx, 64000       ; 320x200 pixels
    rep stosb

    ; Draw red square in center
    ; Center is (160, 100), square is 100x100
    ; So top-left corner is (110, 50)
    
    mov bx, 50          ; Start Y = 50
    mov si, 100         ; Height = 100 rows (use SI instead of DX!)
    
.row_loop:
    ; Calculate offset for this row: Y * 320 + X
    mov ax, bx          ; AX = Y
    mov cx, 320
    mul cx              ; DX:AX = Y * 320 (DX gets overwritten!)
    add ax, 110         ; Add X (110)
    mov di, ax          ; DI = offset
    
    ; Draw 100 red pixels
    mov al, 12          ; Bright red color
    mov cx, 100         ; Width = 100 pixels
    rep stosb
    
    inc bx              ; Next row
    dec si              ; Decrement row counter (SI not affected by mul!)
    jnz .row_loop

.hang:
    hlt
    jmp .hang
