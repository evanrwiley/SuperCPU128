# SuperCPU FPGA Simulation

This directory contains testbenches for verifying the SuperCPU FPGA logic.

## Files
- `tb_supercpu.v`: Top-level testbench. Simulates the C64 bus interface and basic CPU operations.
- `tb_reu.v`: Unit testbench for the REU Emulation module. Verifies DMA transfers, Swap, Verify, and Timing.

## Prerequisites
- A Verilog simulator (e.g., Icarus Verilog, Verilator, ModelSim, Vivado, Quartus).

## How to Run (Icarus Verilog Example)

### 1. Compile and Run REU Test
```bash
iverilog -o tb_reu.vvp tb_reu.v ../rtl/reu_emulation.v
vvp tb_reu.vvp
```

### 2. Compile and Run Top-Level Test
```bash
iverilog -o tb_top.vvp tb_supercpu.v ../rtl/supercpu_top.v ../rtl/reu_emulation.v ../rtl/bus_interface.v ../rtl/registers.v ../rtl/memory_controller.v ../rtl/uart_emulation.v ../rtl/cpu_65816.v ../rtl/pll_sys.v
vvp tb_top.vvp
```

## Verification Goals
- **REU Timing**: Ensure REU respects PHI2 bus timing (1MHz) while running internal logic at 50MHz.
- **Banking**: Verify PLA equations correctly map addresses.
- **Arbitration**: Ensure DMA requests halt the CPU and take over the bus.
