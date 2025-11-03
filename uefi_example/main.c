/*
 * UEFI Bootloader Example
 * 
 * UEFI (Unified Extensible Firmware Interface) is the modern replacement for BIOS.
 * Unlike BIOS (which loads 512-byte boot sectors), UEFI loads PE32+ executables.
 * 
 * Key Differences from BIOS:
 * - Starts in 64-bit long mode (not 16-bit real mode)
 * - Uses C instead of assembly
 * - Has rich APIs (graphics, file systems, networking)
 * - Loads .efi files from FAT32 partitions
 */

#include <efi.h>
#include <efilib.h>

/*
 * EFI_STATUS codes:
 * EFI_SUCCESS           - Operation completed successfully
 * EFI_INVALID_PARAMETER - Bad parameter passed
 * EFI_UNSUPPORTED      - Function not supported
 * EFI_DEVICE_ERROR     - Hardware error occurred
 */

// Entry point for UEFI application
// ImageHandle = Handle to this application's image
// SystemTable = Pointer to UEFI system services
EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable)
{
    EFI_STATUS Status;
    EFI_INPUT_KEY Key;
    
    // Initialize GNU-EFI library
    // Sets up global variables like ST (System Table) and BS (Boot Services)
    InitializeLib(ImageHandle, SystemTable);
    
    // Clear the screen (sets text mode to default)
    // uefi_call_wrapper = Macro to call UEFI functions with proper ABI
    uefi_call_wrapper(SystemTable->ConOut->ClearScreen, 1, SystemTable->ConOut);
    
    // Print welcome message
    // ConOut = Console Output Protocol
    // OutputString = Function to print wide-character strings
    Print(L"\n");
    Print(L"========================================\n");
    Print(L"       UEFI Bootloader Example         \n");
    Print(L"========================================\n\n");
    
    // Print system information
    Print(L"UEFI Firmware Vendor: %s\n", SystemTable->FirmwareVendor);
    Print(L"UEFI Firmware Revision: %d.%d\n", 
          SystemTable->FirmwareRevision >> 16,
          SystemTable->FirmwareRevision & 0xFFFF);
    Print(L"UEFI Specification: %d.%d\n\n",
          SystemTable->Hdr.Revision >> 16,
          SystemTable->Hdr.Revision & 0xFFFF);
    
    // Demonstrate graphics capabilities
    Print(L"Graphics Mode Information:\n");
    Print(L"-------------------------\n");
    
    // Access Graphics Output Protocol (GOP)
    EFI_GUID gopGuid = EFI_GRAPHICS_OUTPUT_PROTOCOL_GUID;
    EFI_GRAPHICS_OUTPUT_PROTOCOL *gop;
    
    Status = uefi_call_wrapper(
        SystemTable->BootServices->LocateProtocol,
        3,
        &gopGuid,
        NULL,
        (VOID**)&gop
    );
    
    if (Status == EFI_SUCCESS) {
        Print(L"Current Mode: %d\n", gop->Mode->Mode);
        Print(L"Max Mode: %d\n", gop->Mode->MaxMode);
        Print(L"Resolution: %dx%d\n",
              gop->Mode->Info->HorizontalResolution,
              gop->Mode->Info->VerticalResolution);
        Print(L"Pixels Per Scan Line: %d\n\n",
              gop->Mode->Info->PixelsPerScanLine);
    } else {
        Print(L"Graphics Output Protocol not available\n\n");
    }
    
    // Show memory map info
    Print(L"Memory Information:\n");
    Print(L"------------------\n");
    
    UINTN MemoryMapSize = 0;
    UINTN MapKey;
    UINTN DescriptorSize;
    UINT32 DescriptorVersion;
    EFI_MEMORY_DESCRIPTOR *MemoryMap = NULL;
    
    // Get memory map size
    Status = uefi_call_wrapper(
        SystemTable->BootServices->GetMemoryMap,
        5,
        &MemoryMapSize,
        MemoryMap,
        &MapKey,
        &DescriptorSize,
        &DescriptorVersion
    );
    
    if (Status == EFI_BUFFER_TOO_SMALL) {
        Print(L"Memory Map Size: %d bytes\n", MemoryMapSize);
        Print(L"Descriptor Size: %d bytes\n\n", DescriptorSize);
    }
    
    // Demonstrate file system access
    Print(L"Boot Device Information:\n");
    Print(L"-----------------------\n");
    
    EFI_LOADED_IMAGE *LoadedImage;
    Status = uefi_call_wrapper(
        SystemTable->BootServices->HandleProtocol,
        3,
        ImageHandle,
        &LoadedImageProtocol,
        (VOID**)&LoadedImage
    );
    
    if (Status == EFI_SUCCESS) {
        Print(L"Image Base: 0x%lx\n", LoadedImage->ImageBase);
        Print(L"Image Size: %ld bytes\n", LoadedImage->ImageSize);
        Print(L"Device Handle: 0x%lx\n\n", LoadedImage->DeviceHandle);
    }
    
    // Interactive menu
    Print(L"\n");
    Print(L"========================================\n");
    Print(L"              Options                   \n");
    Print(L"========================================\n");
    Print(L"1. Draw a colored rectangle\n");
    Print(L"2. Show detailed memory map\n");
    Print(L"3. Exit to UEFI Shell\n");
    Print(L"\nPress a key (1-3)...\n");
    
    // Wait for keypress
    uefi_call_wrapper(SystemTable->BootServices->WaitForEvent, 3, 1, &SystemTable->ConIn->WaitForKey, NULL);
    uefi_call_wrapper(SystemTable->ConIn->ReadKeyStroke, 2, SystemTable->ConIn, &Key);
    
    switch(Key.UnicodeChar) {
        case L'1':
            // Draw a red rectangle if GOP is available
            if (Status == EFI_SUCCESS && gop != NULL) {
                Print(L"\nDrawing red rectangle...\n");
                
                EFI_GRAPHICS_OUTPUT_BLT_PIXEL red = {0, 0, 255, 0}; // BGR format
                
                // Draw 200x100 rectangle at (100, 100)
                uefi_call_wrapper(
                    gop->Blt,
                    10,
                    gop,
                    &red,
                    EfiBltVideoFill,
                    0, 0,           // Source X, Y
                    100, 100,       // Dest X, Y
                    200, 100,       // Width, Height
                    0               // Delta (0 for fill operation)
                );
                
                Print(L"Rectangle drawn! Press any key to continue...\n");
                uefi_call_wrapper(SystemTable->BootServices->WaitForEvent, 3, 1, &SystemTable->ConIn->WaitForKey, NULL);
                uefi_call_wrapper(SystemTable->ConIn->ReadKeyStroke, 2, SystemTable->ConIn, &Key);
            } else {
                Print(L"\nGraphics not available!\n");
            }
            break;
            
        case L'2':
            Print(L"\nMemory map details would be shown here.\n");
            Print(L"(Not fully implemented in this simple example)\n");
            Print(L"Press any key to continue...\n");
            uefi_call_wrapper(SystemTable->BootServices->WaitForEvent, 3, 1, &SystemTable->ConIn->WaitForKey, NULL);
            uefi_call_wrapper(SystemTable->ConIn->ReadKeyStroke, 2, SystemTable->ConIn, &Key);
            break;
            
        case L'3':
        default:
            Print(L"\nExiting to UEFI Shell...\n");
            break;
    }
    
    // Return to UEFI shell
    return EFI_SUCCESS;
}
