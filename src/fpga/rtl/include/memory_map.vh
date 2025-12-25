// Commodore 64/128 Memory Map Definitions
// Derived from user provided mapping files (C64.MemoryMap, C128io, etc.)

`ifndef MEMORY_MAP_VH
`define MEMORY_MAP_VH

// -------------------------------------------------------------------------
// I/O Area ($D000 - $DFFF)
// -------------------------------------------------------------------------

// VIC-II (Video Interface Controller)
// C64/C128: $D000 - $D02E (Shadowed up to $D03F)
`define ADDR_VIC_START      16'hD000
`define ADDR_VIC_END        16'hD03F

// SuperCPU Registers (Custom)
// Mapped to unused area in VIC range or IO2
`define ADDR_SCPU_REGS_START 16'hD070
`define ADDR_SCPU_REGS_END   16'hD07F

// SID (Sound Interface Device)
// C64/C128: $D400 - $D4FF
`define ADDR_SID_START      16'hD400
`define ADDR_SID_END        16'hD4FF

// MMU (Memory Management Unit)
// C128 Only: $D500 - $D50B
`define ADDR_MMU_START      16'hD500
`define ADDR_MMU_END        16'hD50B

// VDC (Video Display Controller 8563)
// C128 Only: $D600 - $D601
`define ADDR_VDC_START      16'hD600
`define ADDR_VDC_END        16'hD6FF

// RAMLink (Memory Expansion / RAM Disk)
// Mapped to IO1 ($DE00) - Must be here for legacy software compatibility
`define ADDR_RAMLINK_START  16'hDE00
`define ADDR_RAMLINK_END    16'hDE26

// UART (ZiModem / SwiftLink)
// Moved to IO2 ($DF20) to avoid conflict with RAMLink at $DE00
// Original SwiftLink uses $DE00, but we can't have two devices there.
`define ADDR_UART_START     16'hDF20
`define ADDR_UART_END       16'hDF2F

// REU (RAM Expansion Unit)
// Mapped to IO2 ($DF00)
`define ADDR_REU_START      16'hDF00
`define ADDR_REU_END        16'hDF0A

// ID Logic (Emulator Detection)
// Mapped to IO2 ($DFA0)
`define ADDR_ID_START       16'hDFA0
`define ADDR_ID_END         16'hDFFF

// CIA 1 (Complex Interface Adapter)
// C64/C128: $DC00 - $DCFF
`define ADDR_CIA1_START     16'hDC00
`define ADDR_CIA1_END       16'hDCFF

// CIA 2 (Complex Interface Adapter)
// C64/C128: $DD00 - $DDFF
`define ADDR_CIA2_START     16'hDD00
`define ADDR_CIA2_END       16'hDDFF

// -------------------------------------------------------------------------
// Special Addresses
// -------------------------------------------------------------------------

// REU Trigger (Write Only)
`define ADDR_REU_TRIGGER    16'hFF00

// Bridge Window Base (Default)
`define ADDR_BRIDGE_DEF     16'h033C

`endif // MEMORY_MAP_VH
