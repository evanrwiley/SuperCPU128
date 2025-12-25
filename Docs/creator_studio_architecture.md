# SuperCPU Creator Studio: Architecture

The **Creator Studio** is a comprehensive, AI-powered Integrated Development Environment (IDE) for the C64/C128. It goes beyond simple coding to handle the entire lifecycle of software creation: Asset Management, Memory Budgeting, and Project Scoping.

## 1. The "Retro Architect" (AI Project Manager)
This is the core intelligence. It acts as a Lead Developer who understands the hardware constraints.

### Responsibilities
-   **Feasibility Analysis**: "Can we fit 5 more levels into 64KB?"
-   **Hardware Negotiation**: "You want 10 sprites? The C64 only has 8 hardware sprites. Shall we use multiplexing (flicker) or overlays?"
-   **Memory Budgeting**: Tracks every byte. "We have 12KB free. Your new music track will take 4KB."

### Workflow Example (The "Donkey Kong" Scenario)
1.  **Ingest**: User provides `game.prg`.
2.  **Deconstruct**: The system rips the binary into components:
    -   `sprites.bin` (Graphics)
    -   `sid.bin` (Audio)
    -   `code.asm` (Logic)
    -   `map.bin` (Level Data)
3.  **Scope**: User asks: "Add 3 levels."
4.  **Architect Response**: "Analyzing... Current map data is $0800 bytes per level. 3 levels = $1800 bytes (6KB). We only have 4KB free in the main block. **Recommendation**: Enable REU support or compress the level data."

## 2. The Tool Suite
These tools run on the ARM processor (backend) with a UI on the C64 (frontend) or VS Code.

### A. Sprite Studio (AI-Assisted)
-   **User**: "Draw a futuristic robot."
-   **AI**: Generates a 24x21 pixel monochrome or multicolor bitmap.
-   **Constraint**: Enforces C64 palette (16 colors) and resolution.

### B. SID Lab (AI Composer)
-   **User**: "Make a spooky bassline."
-   **AI**: Generates register dumps for the SID chip (Waveform, ADSR, Filter).

### C. Level Architect
-   **User**: "Generate a dungeon maze."
-   **AI**: Creates a tilemap array based on the game's existing tile set.

## 3. Project Structure (The "Manifest")
Every project has a `project.json` that the AI reads to understand the state.

```json
{
  "project_name": "Donkey Kong Mod",
  "target_hardware": "C64",
  "extensions": ["REU", "SuperCPU"],
  "memory_map": {
    "code_start": 2049,
    "code_end": 16384,
    "free_space": 38911
  },
  "assets": {
    "sprites": {"count": 128, "size_kb": 8},
    "levels": {"count": 4, "size_kb": 4}
  }
}
```

## 4. Modes of Operation
-   **Autonomous Mode**: "Fix the color clash in the sprite." -> AI edits the bytes directly.
-   **Learning Mode**: "How do I fix the color clash?" -> AI explains Multicolor Mode constraints (2 shared colors, 1 unique).
