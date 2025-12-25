#ifndef SUPERCPU_MEMORY_MAP_H
#define SUPERCPU_MEMORY_MAP_H

#include <stdint.h>

/*
 * SuperCPU / Sysop-64 Shared Memory Interface
 * 
 * This defines the memory layout used by the ARM Linux side to communicate
 * with the FPGA hardware that emulates the SuperCPU.
 */

// Base Address of the FPGA Bridge in ARM Physical Memory
// Note: This depends on the DE10-Nano HPS-to-FPGA bridge configuration.
// Standard DE10-Nano usually maps this to 0xC0000000 or similar.
#define FPGA_BRIDGE_BASE    0xC0000000
#define FPGA_BRIDGE_SPAN    0x00100000  // 1MB Window

/*
 * SuperCPU Registers (Relative to Base)
 * Based on CMD SuperCPU User Guide
 */
#define SCPU_REG_VIC_BANK   0xD074  // VIC Bank Selection
#define SCPU_REG_SPEED      0xD07A  // Speed Control (Turbo/Normal)
#define SCPU_REG_ENABLE     0xD07B  // SuperCPU Enable/Disable
#define SCPU_REG_MEM_CFG    0xD07E  // Memory Configuration

/*
 * C128 Specific Registers
 */
#define C128_MMU_CFG        0xD500  // MMU Configuration Register
#define C128_MMU_MODE       0xD505  // Mode Configuration

/*
 * Sysop-64 Specific Control Registers (Custom)
 * These are new registers we define for Linux control
 */
#define SYSOP_REG_CMD       0xFF00  // Command Register
#define SYSOP_REG_STATUS    0xFF01  // Status Register
#define SYSOP_REG_DATA      0xFF02  // Data Port

#endif // SUPERCPU_MEMORY_MAP_H
