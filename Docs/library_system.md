# SuperCPU Library System Architecture

## Overview
The SuperCPU Library System is a modern, AI-enhanced storage solution for Commodore 64/128 software. It moves beyond simple file listing by implementing a database-driven architecture that allows for rich metadata, searching, and dynamic organization.

## Core Components

### 1. Database (`library.db`)
We use **SQLite** as the primary storage engine for metadata. This allows for fast querying and filtering on the embedded Linux system.

**Schema:**
- **Items Table**:
  - `id`: Unique Identifier
  - `title`: Software Title
  - `filename`: Original filename
  - `file_path`: Path to binary in storage
  - `year`: Release Year
  - `publisher`: Publisher Name
  - `genre`: Primary Genre (e.g., "Platformer")
  - `ai_summary`: AI-generated description
  - `ai_tags`: JSON array of tags (e.g., ["Side Scrolling", "Sci-Fi"])
  - `favorite`: Boolean flag

### 2. Storage Backend
- **Binary Storage**: Files are stored in `data/storage/` with unique filenames to prevent collisions.
- **JSON Export/Import**: The system supports exporting the entire library to a JSON file. This ensures **portability** and allows users to manually edit metadata on a PC if desired.

### 3. AI Enrichment Service
The `AiEnricher` service runs in the background. When a new item is added (Ingested):
1. It is placed in a processing queue.
2. The service constructs a prompt with available metadata (Title, Year).
3. It queries the local or remote LLM (e.g., Ollama/Llama3).
4. The LLM returns a structured JSON response with a Summary, Genre, and Tags.
5. The database is updated automatically.

### 4. Virtual File System (VFS)
The Library is exposed to the C64 via the **Virtual Drive Service**. Instead of mapping to a physical folder, the "Library Drive" generates directory listings dynamically based on database queries.

**Directory Structure:**
- `//LIB/` (Root)
  - `ALL GAMES/` -> Flat list of all PRGs.
  - `BY YEAR/` -> Subdirectories for each year (1983, 1984...).
  - `BY GENRE/` -> Subdirectories for each genre (Action, Puzzle...).
  - `FAVORITES/` -> Items marked as favorite.

## Workflows

### Ingestion (RAM Capture)
1. User loads a program on the C64 (Tape, Disk, or Type-in).
2. User triggers "Ingest from RAM" via the Linux Menu or CLI.
3. System reads the C64 RAM (via FPGA Bridge).
4. System saves the binary to storage.
5. System triggers AI Enrichment.
6. Item becomes available in the Library Drive immediately.

### Ingestion (File Import)
1. User places `.prg` or `.d64` files in an import folder.
2. System scans and imports them into the database.
3. AI Enrichment runs for each item.

### Browsing & Loading
1. User mounts the Library Drive (e.g., Device 10).
2. User loads the directory: `LOAD "$",10`.
3. User navigates the VFS structure.
4. User loads a game: `LOAD "ZORK",10`.
   - The Virtual Drive Service locates the file path from the DB.
   - It streams the binary data to the C64.

## Future Enhancements
- **TOSEC Integration**: Match file hashes against the TOSEC database for accurate identification.
- **Web Interface**: A web-based library manager for easier organization from a PC.
- **Cloud Sync**: Sync library metadata and save states to cloud storage.
