# AI Integration Guide: SuperCPU & Modern Tools

This guide explains how the AI Co-Processor interacts with legacy C64 tools and how to set up a modern development environment using VS Code.

## 1. AI Interaction with Legacy Tools
The AI cannot "see" the screen or "type" on the physical keyboard like a human, but we have built special hardware bridges to allow it to interact with C64 software.

### The "Ghost Typist" (Virtual Keyboard)
The AI can inject keystrokes directly into the C64's keyboard buffer. This allows it to:
- Type code into **Merlin Assembler**.
- Enter commands into **SuperMon**.
- Navigate menus in legacy software.

**Mechanism:**
1. The AI (running on the ARM core) writes ASCII characters to the `debug_bridge`.
2. The `debug_bridge` uses DMA to write these characters into the C64's keyboard buffer (Address `$0277-$0280`).
3. The C64 Kernal's interrupt handler sees the keys and processes them as if you typed them.

### The "Screen Scraper" (Visual Feedback)
The AI can read the C64's screen memory to understand what is happening.
- **Mechanism:** The `debug_bridge` reads the Screen RAM (usually `$0400-$07E7`) and sends the character data back to the AI.
- **Usage:** If Merlin displays an error message, the AI can read it and suggest a fix.

## 2. Modern Development Environment (VS Code)
While running VS Code directly on the FPGA (via `code-server`) is possible, it is resource-heavy. We recommend the **Remote - SSH** approach.

### Recommended Setup
1. **Host (Your PC):** Run VS Code on your powerful Windows/Mac/Linux machine.
2. **Target (DE10-Nano):** The ARM Linux system runs an SSH server.
3. **Connection:** Use the [Remote - SSH](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-ssh) extension to connect.

### Workflow
1. **Edit:** Write 6502/65816 assembly in VS Code with full syntax highlighting and git integration.
2. **Build:** Run `64tass` or `cc65` directly in the VS Code terminal (which is actually running on the DE10-Nano).
3. **Deploy:** The build script writes the binary to the shared memory region.
4. **Run:** The C64 (via the AI Bridge) detects the new binary and executes it.

### VS Code Extensions
- **6502/65816 Assembly**: Syntax highlighting.
- **C/C++**: If writing mixed C/Assembly.
- **Remote - SSH**: Essential for connecting to the board.

## 3. Recommended Legacy Tools
If you prefer the authentic experience, these tools work perfectly on the SuperCPU:
- **Assembler:** `Merlin 128` or `Turbo Macro Pro`.
- **Monitor:** `SuperMon 64` or the built-in `JiffyDOS` monitor.
- **Disassembler:** `Regenerator` (runs on PC, but great for analyzing dumps).

## 4. The "SuperDebug" Bridge
We have implemented a hardware debugger (`debug_bridge.v`) that allows VS Code to:
- **Halt** the SuperCPU.
- **Step** through instructions.
- **Inspect** memory and registers in real-time.

This provides a "God Mode" view of the system that was impossible on original hardware.

## 5. AI Metadata Enrichment
Beyond coding assistance, the AI plays a crucial role in organizing your software library.

### The "Librarian" Agent
When you ingest a program into the Library System (from RAM or disk), the `AiEnricher` service activates.

**Workflow:**
1. **Identification**: The system extracts the filename and any internal strings (e.g., "CBM" headers).
2. **Query**: It sends this data to the local LLM (e.g., Ollama running Llama3) with a prompt like: *"Identify this C64 game 'ZORK' and provide a summary, genre, and tags."*
3. **Enrichment**: The AI returns a structured JSON object:
   ```json
   {
     "summary": "A classic text adventure game set in the Great Underground Empire.",
     "genre": "Interactive Fiction",
     "tags": ["Infocom", "Text Adventure", "Fantasy"]
   }
   ```
4. **Storage**: This metadata is saved to the SQLite database, making the game searchable by genre or tag on the C64.

### Configuration
You can configure the AI model and endpoint in `config/supercpu_config.json`:
```json
"ai_coprocessor": {
    "enabled": true,
    "api_endpoint": "http://localhost:11434/api/generate",
    "model": "llama3"
}
```
