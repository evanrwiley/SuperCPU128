# SuperCPU Creator Studio

**Status**: 🟢 Code Complete (v1.0)
**Platform**: Commodore 64/128 + DE10-Nano (SuperCPU Emulation)

## Overview
The **SuperCPU Creator Studio** is a hybrid hardware/software development environment that transforms a Commodore 64 into an AI-assisted workstation. It combines a 20MHz 65816 accelerator (FPGA) with a Linux-based AI Co-Processor (ARM) to enable real-time code generation, asset creation, and compilation directly from the C64.

## 🏗 Architecture

### 1. The Hardware (FPGA)
- **Core**: W65C816S Soft Core @ 20MHz.
- **Memory**: 16MB SuperRAM + REU Emulation.
- **Bridge**: Memory-mapped I/O at `$DE00-$DEFF` connects the C64 bus to the ARM processor.

### 2. The AI Co-Processor (ARM/Linux)
- **Bridge Daemon (`daemon.c`)**: A high-performance C service that monitors the FPGA bridge. It intercepts commands written to `$DE00` and triggers Python tools.
- **AI Service (`creator_cli.py`)**: The "brain" of the system. It accepts natural language prompts from the C64, queries AI models (Copilot/Ollama), and generates 6502/65816 assembly or sprite/SID data.
- **Knowledge Base**: A strict set of JSON definitions (`c64_def.json`) ensures the AI respects hardware limits (e.g., 8 sprites, 3 SID voices).

### 3. The Frontend (C64)
- **IDE (`ide_main.asm`)**: A native 65816 application running on the C64. It provides a menu-driven interface to:
  - Write prompts ("Make a sprite of a spaceship").
  - Trigger builds.
  - View status and error logs.

## 🚀 Installation

### Prerequisites
- **Hardware**: Terasic DE10-Nano + Sysop-64 Carrier Board.
- **OS**: Terasic Linux (MicroSD card).
- **Network**: WiFi or Ethernet connection on the DE10-Nano.

### One-Click Setup
1. SSH into your DE10-Nano:
   ```bash
   ssh root@192.168.x.x
   ```
2. Clone this repository:
   ```bash
   git clone https://github.com/your-repo/c128SuperCPU.git
   cd c128SuperCPU
   ```
3. Run the installer:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```
   *This will install Python dependencies, compile the bridge daemon, and set up the systemd service.*

## 🎮 Usage

1. **Boot the C64**: Turn on your C64 with the SuperCPU cartridge inserted.
2. **Load the IDE**:
   ```basic
   LOAD "IDE", 8
   RUN
   ```
3. **Generate Code**:
   - Select **"AI Assistant"** from the menu.
   - Type a request: *"Create a raster bar effect in assembly."*
   - Press **RETURN**. The C64 will pause while the ARM processor generates the code.
   - The result will be written to `source.asm` on the SD card (accessible via the IDE).

4. **Create Assets**:
   - Select **"Sprite Wizard"**.
   - Type: *"A walking robot facing right."*
   - The AI will generate the sprite data and load it into memory.

## 📂 Project Structure

- `src/fpga/`: Verilog sources for the SuperCPU core.
- `src/firmware/`: Boot ROMs and JiffyDOS extensions.
- `src/software/`:
  - `bridge_daemon/`: C code for the FPGA<->Linux bridge.
  - `c64_ui/`: 65816 Assembly source for the C64 frontend.
  - `ai_engine/`: Python AI logic and prompt templates.
  - `knowledge_base/`: JSON hardware definitions.
- `install.sh`: Deployment automation script.

## 🔧 Technical Reference

### Memory Map (Bridge Interface)
The communication between the C64 and the ARM processor happens via a shared memory window at `$DE00`.

| Address | Register Name | R/W | Description |
| :--- | :--- | :--- | :--- |
| `$DE00` | `BRIDGE_CMD` | W | Command Type (e.g., `$10`=Build, `$20`=Sprite) |
| `$DE01` | `BRIDGE_ADDR_LO` | W | Parameter Address Low Byte |
| `$DE02` | `BRIDGE_ADDR_HI` | W | Parameter Address High Byte |
| `$DE03` | `BRIDGE_PARAM` | W | Additional Parameter / Length |
| `$DE10` | `BRIDGE_VALID` | W | Set to `1` to trigger the ARM Daemon |
| `$DE14` | `BRIDGE_DONE` | R | Reads `1` when ARM has finished processing |

### Command Codes
| Code | Name | Description |
| :--- | :--- | :--- |
| `$10` | `CMD_BUILD` | Triggers the 65816 Assembler on the ARM side. |
| `$20` | `CMD_SPRITE` | Generates a sprite from a text prompt. |
| `$30` | `CMD_SID` | Generates a SID sound effect or melody. |
| `$40` | `CMD_AI_CFG` | Updates AI model settings (e.g., temperature). |

## ❓ Troubleshooting

**Issue: The C64 hangs when sending a command.**
- **Cause**: The `bridge_daemon` service is not running on the Linux side.
- **Fix**: SSH into the DE10-Nano and run `systemctl status supercpu-bridge`. If it's stopped, run `systemctl start supercpu-bridge`.

**Issue: "Bridge Error" in the IDE.**
- **Cause**: The FPGA core is not loaded, or the memory map is incorrect.
- **Fix**: Ensure the `supercpu_top.rbf` bitstream is loaded. Verify that `$DE00` is readable in the C64 Monitor.

## 📜 License
MIT License
