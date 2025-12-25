# Retro Coding Guidelines & Best Practices

## 1. General 6502/65816 Rules
-   **Self-Modifying Code**: Acceptable and common for speed, but makes debugging harder. Use sparingly.
-   **Page Boundaries**: Avoid crossing page boundaries (e.g., `$C0FF` to `$C100`) in tight loops; it costs an extra cycle.
-   **Zero Page**: Use ZP addresses (`$00-$FF`) for your most frequently accessed variables. It saves 1 cycle and 1 byte per instruction.

## 2. Commodore 64 Specifics
-   **Interrupts**: The standard IRQ handler points to `$EA31`. If you hook `$0314`, ensure you jump back to `$EA31` or `$EA81` to maintain keyboard/cursor scanning.
-   **IO Port**: `$01` controls the memory map.
    -   `$37`: Default (Basic + Kernal + IO).
    -   `$35`: No Basic (Ram + Kernal + IO).
    -   `$34`: All RAM (except IO).
-   **Bad Lines**: The VIC-II steals CPU cycles every 8th scanline to fetch character data. Timing-critical code must account for this jitter.

## 3. Commodore 128 Specifics
-   **2 MHz Mode**:
    -   Enabled via `$D030` (Bit 0).
    -   **Warning**: The VIC-IIe cannot display graphics in 2MHz mode (screen goes black or garbage). Only use 2MHz during VBlank or if using the 80-column VDC.
-   **Bank Switching**:
    -   The C128 has 128KB RAM (Bank 0 and Bank 1).
    -   Code running in Bank 0 cannot directly read data in Bank 1. You must use the MMU (`$FF00`) or the `LDA $xxxx` (Load Far) helper routines.
-   **VDC (80 Column)**:
    -   Accessed via `$D600` (Address) and `$D601` (Data).
    -   It is slow. You must poll the "Ready" bit (Bit 7 of `$D600`) before writing, or use the SuperCPU's speed to outrun it (wait loops required).

## 4. SuperCPU Specifics
-   **16-bit Mode**: The 65816 can handle 16-bit Accumulator and Index registers.
    -   `REP #$30`: Switch to 16-bit mode.
    -   `SEP #$30`: Switch to 8-bit mode.
-   **Stack**: The stack is still at `$0100` in Emulation mode, but can be moved in Native mode.
-   **Optimization**: Unroll loops. The 16MB address space allows for massive lookup tables (e.g., pre-calculated sine waves).
