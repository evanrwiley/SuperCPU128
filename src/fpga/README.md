# FPGA Development Guide

## ⚠️ CRITICAL WARNING: PINOUT VERIFICATION
We are building this FPGA core **from scratch** without the official Sysop-64 schematic.
**DO NOT FLASH A BITSTREAM** until you have verified the pinout. Sending a signal to a pin that the C64 is also driving (Bus Contention) can **destroy your DE10-Nano or C64**.

## How to Verify Pinout
1.  **Disconnect** the DE10-Nano from the C64.
2.  Use a **Multimeter** in Continuity Mode.
3.  Place one probe on the **C64 Edge Connector** (e.g., Pin 6 = PHI2).
4.  Run the other probe along the **DE10-Nano GPIO Headers** (J2/J3/J4) until it beeps.
5.  Record the GPIO Pin Number (e.g., GPIO_0_10).
6.  Update `src/fpga/quartus_project/supercpu.qsf` with the correct `PIN_XXX` assignment.

## Project Structure
- `rtl/`: Verilog source code.
- `quartus_project/`: Intel Quartus Prime project files.
- `testbench/`: Simulation files.

## Building the Core
1.  Open `quartus_project/supercpu.qpf` in Quartus Prime Lite.
2.  Run **Analysis & Synthesis** to check for errors.
3.  Run **Pin Planner** to visualize assignments.
4.  Run **Compile** to generate the `.sof` / `.rbf` file.
