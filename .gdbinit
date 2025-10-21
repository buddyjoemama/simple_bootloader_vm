# GDB configuration for bootloader debugging
set confirm off
set verbose off
set prompt \033[31mgdb$ \033[0m
set disassemble-next-line on

# Connect to QEMU
define connect
    target remote localhost:1234
end

# Set up for 16-bit real mode debugging
define setup16
    set architecture i8086
    set disassembly-flavor intel
end

# Set up for 32-bit protected mode debugging  
define setup32
    set architecture i386
    set disassembly-flavor intel
end

# Bootloader entry point
define bootstart
    setup16
    break *0x7c00
    continue
    display/i $pc
end

# Kernel entry point
define kernelstart
    setup16
    break *0x10000
    continue  
    display/i $pc
end

# Show next few instructions
define next5
    x/5i $pc
end

# Show registers in 16-bit format
define regs16
    printf "AX=%04x BX=%04x CX=%04x DX=%04x\n", $ax, $bx, $cx, $dx
    printf "SI=%04x DI=%04x BP=%04x SP=%04x\n", $si, $di, $bp, $sp
    printf "CS=%04x DS=%04x ES=%04x SS=%04x\n", $cs, $ds, $es, $ss
    printf "IP=%04x FLAGS=%04x\n", $ip, $eflags
end

# Show memory at current location
define showmem
    x/16bx $cs*16+$ip
end

# Step and show state
define stepshow
    stepi
    regs16
    next5
end

echo \033[32m
echo ===== Bootloader Debugger Ready =====
echo Available commands:
echo   connect     - Connect to QEMU
echo   bootstart   - Break at bootloader entry (0x7c00)
echo   kernelstart - Break at kernel entry (0x10000)  
echo   regs16      - Show 16-bit registers
echo   next5       - Show next 5 instructions
echo   stepshow    - Step and show registers + instructions
echo   setup16     - Switch to 16-bit mode
echo   setup32     - Switch to 32-bit mode
echo \033[0m
