# Copilot Instructions

This file guides AI coding agents on the specific architecture, conventions, and workflows for this project: **SuperCPU Recreation & Enhancement**.

## 🏗 Project Architecture
- **Overview**: This project aims to recreate and enhance the **CMD SuperCPU** accelerator for Commodore 64/128 computers using modern FPGA hardware.
- **Hardware Platform**:
  - **Target Board**: DE10-Nano (FPGA) + Sysop-64 Carrier Board (or compatible).
  - **Interface**: C64/C128 Expansion Port (Cartridge Port). *Note: Requires additional lines (_CHAREN, _HIRAM, _LORAM) for full control.*
- **Core Components**:
  - **CPU**: W65C816S Soft Core (running at ~20MHz or higher).
  - **Memory**: Up to 16MB RAM (SuperRAM emulation) + REU (Ram Expansion Unit) emulation.
  - **Logic**: SuperCPU compatible banking, registers, and JiffyDOS integration.
- **Design Philosophy**:
  - **Compatibility**: Maintain 100% software compatibility with original SuperCPU software.
  - **Modularity**: Separate the Bus Interface, CPU Core, and Memory Controller logic in HDL.

## 🛠 Tech Stack & Conventions
- **Hardware Description**: Verilog / SystemVerilog (preferred for FPGA cores).
- **Software/Firmware**:
  - **6502/65816 Assembly**: For firmware, patches, and test code.
  - **C/C++**: For support tools or Linux-side integration (if using Sysop-64 Linux features).
- **Tools**:
  - **FPGA**: Intel Quartus Prime (for DE10-Nano).
  - **Assemblers**: 64tass, ca65 (cc65 suite).
  - **Emulation**: VICE (for testing software before hardware deployment).

## 🚀 Workflows
- **Development**:
  - **HDL**: Edit Verilog files in `src/fpga/`.
  - **Firmware**: Assemble boot ROMs/drivers in `src/firmware/`.
- **Build**:
  - **FPGA Bitstream**: Run Quartus synthesis (add command/script reference).
  - **ROM Images**: `make roms` (placeholder).
- **Testing**:
  - **Simulation**: Verilator or ModelSim for bus timing verification.
  - **Hardware**: Deploy `.rbf` or `.sof` to DE10-Nano and boot C64.

## 📝 Coding Guidelines
- **AI Behavior**:
  - **Context Awareness**: When writing Verilog, consider C64 bus timing constraints (PHI2 clock).
  - **Retro-Computing**: Prefer efficient Assembly code for 8-bit/16-bit operations.
  - **Documentation**: Reference the [SuperCPU User Guide](https://archive.org/stream/CMD_SuperCPU_128_V2_Users_Guide/CMD_SuperCPU_128_V2_Users_Guide_djvu.txt) for register definitions.

## 📚 References
- **SuperCPU**:
  - [Wikipedia](https://en.wikipedia.org/wiki/SuperCPU)
  - [User Guide (Text)](https://archive.org/stream/CMD_SuperCPU_128_V2_Users_Guide/CMD_SuperCPU_128_V2_Users_Guide_djvu.txt)
  - [Tech Specs](https://web.archive.org/web/20090623063229/http://ftp.giga.or.at/pub/c64/supercpu/superspec.html)
- **Sysop-64 (Hardware Base)**:
  - [GitHub Repo](https://github.com/Bloodmosher/Sysop-64) (Carrier board & FPGA interface)

