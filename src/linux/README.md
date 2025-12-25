# SuperCPU Linux Tools & Configuration

This directory contains the Linux-side software stack for the SuperCPU, including the AI services, Library Manager, and Hardware Abstraction Layer.

## Directory Structure
- `tools/`: CLI utilities for managing the system.
  - `reu_tool.py`: Command-line interface for REU management (Load/Save/Autoload).
  - `config_loader.py`: Applies JSON configuration to FPGA registers.
- `services/`: Long-running background services.
  - `library_manager.py`: Core logic for the software library (Ingest, Search, Export).
  - `library_db.py`: SQLite database abstraction.
  - `ai_enricher.py`: Background service that fetches metadata from AI models.
  - `reu_manager.py`: Handles REU memory transfer and persistence.
  - `virtual_drive_service.py`: Emulates C64 disk drives, including the VFS Library Drive.
  - `fpga_interface.py`: Low-level memory mapping (HPS-to-FPGA bridges).
- `config/`: Configuration files.
  - `supercpu_config.json`: Main system config (Memory, AI, Network).
- `ui/`: User Interfaces.
  - `menu.py`: TUI (Text User Interface) for system management.

## Key Features

### 1. Library System
The Library System uses a hybrid SQLite/JSON architecture to manage C64 software.
- **Database**: `data/library.db` stores metadata (Title, Year, Genre, AI Tags).
- **Storage**: `data/storage/` holds the actual binary files (PRG, D64).
- **AI Enrichment**: When a program is ingested (from RAM or file), the `AiEnricher` service queries an LLM to generate a summary and tags.
- **Virtual File System**: The library is exposed to the C64 as a browsable directory structure via the Virtual Drive Service.

### 2. REU Management
The REU Manager allows for instant saving and restoring of the 16MB SuperRAM.
- **Autoload**: Configure a specific image to load on boot (e.g., for Instant GEOS).
- **Tools**: Use `reu_tool.py` or the TUI Menu to manage images.

### 3. Virtual Drive
Maps Linux directories and the Library VFS to C64 device IDs.
- **Local**: Maps a local Linux folder.
- **SMB**: Mounts a network share.
- **Library**: Exposes the `//LIB` VFS.

## Configuration (`config/supercpu_config.json`)
The system is configured via a JSON file that controls:
- **Clock Speed**: Configurable (e.g., 20MHz, 40MHz, etc.).
- **Memory**: SuperRAM size and REU emulation.
- **AI**: API endpoints and model selection.
- **Drives**: Virtual drive mapping.

## Usage

### REU Tool
```bash
# Save current REU state
python3 src/linux/tools/reu_tool.py save my_snapshot.reu

# Load a snapshot
python3 src/linux/tools/reu_tool.py load my_snapshot.reu

# Enable Autoload
python3 src/linux/tools/reu_tool.py autoload --enable --file my_snapshot.reu
```

### System Menu
Run the TUI menu for an interactive experience:
```bash
python3 src/linux/menu.py
```
