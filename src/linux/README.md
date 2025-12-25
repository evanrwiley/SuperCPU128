# SuperCPU Linux Tools & Configuration

This directory contains the Linux-side software stack for the SuperCPU.

## Directory Structure
- `tools/`: Low-level CLI utilities (refactored from original Sysop-64 binaries).
- `config/`: Configuration files (JSON).
- `ui/`: User Interface (TUI/Web).

## Configuration (`config/supercpu_config.json`)
The system is configured via a JSON file that controls:
- **Clock Speed**: Configurable (e.g., 20MHz, 40MHz, etc.).
- **Memory**: SuperRAM size and REU emulation.
- **AI**: API endpoints and model selection.

## Tools
- `config_loader.py`: Reads the JSON config and applies settings to the FPGA registers.
- `c64init.sh`: Boot script (legacy support).

## Usage
To apply configuration:
```bash
python3 src/linux/tools/config_loader.py
```
