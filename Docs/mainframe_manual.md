# SuperCPU Mainframe Manual

**Welcome to the SuperCPU Mainframe System.**

This document explains how to operate the integrated PDP-11/70 mainframe environment. This system is based on the historic DEC PDP-11 architecture and runs authentic operating systems from the 1970s and 80s via the SIMH emulator.

## 1. Getting Started

### Connecting to the Mainframe
The Mainframe is accessed via the C64/C128 "Modem" interface.

1.  **Load Terminal Software:** Launch your preferred terminal program (e.g., CCGMS, Novaterm, or DesTerm).
2.  **Configure Settings:**
    *   Baud Rate: 57600 (or highest supported)
    *   Emulation: VT100 or ANSI
3.  **Dial In:**
    *   Type `ATDT SIMH` and press Return.
    *   You will see the PDP-11 boot sequence.

### Controlling the Simulator
The simulator (SIMH) has a control interface separate from the guest OS.
*   **Stop Simulation:** Press `CTRL+E`. This drops you to the `sim>` prompt.
*   **Resume:** Type `CONT` at the `sim>` prompt.
*   **Exit:** Type `QUIT` at the `sim>` prompt (or hang up the modem with `+++` then `ATH`).

## 2. Operating Systems

The SuperCPU supports multiple operating systems. These are stored in `data/pdp11/systems/`.

### RSTS/E (Resource Sharing Time Sharing System)
*   **Best for:** The classic multi-user BASIC experience.
*   **Login:** Usually requires an account (e.g., `1,2`).
*   **Commands:**
    *   `OLD`: Load a program.
    *   `RUN`: Run a program.
    *   `CAT` or `DIR`: List files.
    *   `BYE`: Log off.

### UNIX V7
*   **Best for:** C programming and historical research.
*   **Login:** Usually `root` or `guest`.
*   **Commands:** Standard Unix commands (`ls`, `cd`, `cc`, `vi`).

### RT-11
*   **Best for:** Real-time applications and single-user efficiency.
*   **Commands:** `DIR`, `TYPE`, `MACRO`, `LINK`.

## 3. Managing Software

### The "Tape Drive" Workflow
Since the PDP-11 is virtual, we can "mount" files from the SuperCPU Library into the PDP-11.

1.  **Prepare File:** Ensure the file (e.g., `adventure.bas`) is in your Library.
2.  **Mount Tape:**
    *   Stop simulation (`CTRL+E`).
    *   Type: `attach ts0 ../../../library/adventure.tap`
    *   Resume (`CONT`).
3.  **Read on PDP-11:**
    *   (RSTS/E Example): `PIP file.bas=MT0:`

## 4. Front Panel (Virtual & Physical)

### Virtual Switch Register
If you do not have the physical PiDP-11 panel, you can manipulate the switches via software commands.
*   **Set Switches:** `set cpu sr=<value>` (at `sim>` prompt).
*   **Read Display:** `show cpu data`

### Physical PiDP-11 Panel (Optional)
If you have connected the PiDP-11 Front Panel kit:
*   **Switches:** Control the simulation in real-time.
*   **LEDs:** Display the Address/Data bus activity.
*   **Address Select:** Rotate the knob to choose what the Data LEDs display (Program Counter, Register R0-R7, etc.).

## 5. Troubleshooting

*   **"Not Found" Error:** Ensure you have placed a valid disk image in `data/pdp11/systems/<os>/` and updated `boot.ini`.
*   **Stuck Connection:** Type `+++` (wait 1 sec) then `ATH` to force a disconnect.
