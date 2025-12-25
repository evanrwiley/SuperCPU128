# SuperCPU AI Studio: Architecture Design

## 1. The "Neural Monitor" (Native C64 Suite)
We will create a native 65816 application (`neural_mon.prg`) that resides in the FPGA's ROM or is loaded into RAM.

### Features for Novices
- **"Explain This"**: Cursor over a line of code -> Press F1 -> AI displays a popup window explaining the logic in plain English.
- **"Fix It"**: Program crashed? Press Reset -> "Analyze Crash" -> AI looks at the Stack and PC to tell you *why* it crashed (e.g., "You stuck in an infinite loop at $C000").
- **BASIC to ASM**: Type BASIC code, press F5 -> AI generates the optimized Assembly version and injects it into memory.

### Features for Experts
- **"Optimize"**: Highlight a routine -> Press F3 -> AI suggests a cycle-exact optimization.
- **"Commentator"**: Run a pass over a binary -> AI generates a fully commented source file (compatible with Merlin/64tass).
- **"Porting Assistant"**: "Convert this C64 Sprite routine to C128 VDC commands."

## 2. The Workflow

### Scenario: Decompiling & Learning
1.  **Load**: User loads `unknown_game.prg`.
2.  **Detect**: FPGA detects writes to `$0801` (BASIC) or `$080D` (Machine Code).
3.  **Prompt**: Neural Monitor pops up: *"New Program Detected. Analyze?"*
4.  **Action**: User selects "Yes".
5.  **Process**:
    -   ARM reads memory `$0801` to End of Program.
    -   ARM runs a "Smart Disassembler" (local logic).
    -   ARM sends the disassembly to AI with the prompt: *"Add comments explaining the game logic, focusing on hardware register usage."*
6.  **Result**: The C64 screen splits. Left side: Raw Code. Right side: AI Comments.

## 3. The "Context Builder" (The Secret Sauce)
The AI is smart, but it hallucinates if it doesn't have context. We must provide a **Hardware Definition Layer**.

When sending code to the AI, we don't send:
`LDA $D020`

We send:
`LDA $D020 ; [HARDWARE: VIC-II Border Color]`

This ensures the AI knows exactly what the code is doing relative to the Commodore hardware.
