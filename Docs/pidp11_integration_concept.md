# PiDP-11 Front Panel Integration Concept

**Status:** Proposal / Conceptual  
**Target Hardware:** DE10-Nano (Cyclone V SoC) + PiDP-11 Front Panel Kit  
**Goal:** Integrate the realistic PDP-11/70 front panel switches and LEDs with the SuperCPU architecture, leveraging the FPGA for superior performance and C64 interactivity.

---

## 1. Overview
The [PiDP-11](https://obsolescence.dev/pidp11/PiDP-11_Manual.pdf) is a replica of the PDP-11/70 front panel designed for the Raspberry Pi. It uses a multiplexed LED/Switch matrix connected to the Pi's GPIO header.

This proposal outlines how to adapt this hardware for the **SuperCPU (DE10-Nano)**. Unlike the Raspberry Pi implementation, which relies on the CPU for multiplexing, we will offload the display logic to the FPGA, resulting in zero-overhead emulation and smoother visuals.

## 2. Hardware Interface (The "Pin Scrambler")
The DE10-Nano has a 40-pin GPIO header (JP1), but the pinout differs from the Raspberry Pi. Direct connection is **NOT** possible and may damage hardware.

### Required Adapter
A custom ribbon cable or PCB adapter is required to map the DE10-Nano GPIO pins to the PiDP-11 connector.

*   **PiDP-11 Requirements:**
    *   Row Drivers (LED Anodes / Switch Commons)
    *   Column Drivers (LED Cathodes / Switch Inputs)
    *   I2C (Optional, for RTC if used)
*   **DE10-Nano Mapping:**
    *   Map PiDP pins to available FPGA I/O pins on Header JP1.
    *   Voltage Level: Ensure 3.3V compatibility (DE10-Nano GPIO is 3.3V).

## 3. FPGA Architecture (The "Driver" Core)
Instead of the ARM CPU bit-banging GPIOs thousands of times per second, we implement a hardware driver in Verilog.

### Verilog Module: `pidp11_driver.v`
*   **Function:** Handles the high-speed multiplexing (scanning) of the LED matrix and debouncing of switches.
*   **Refresh Rate:** Can run at >1kHz for flicker-free operation, independent of CPU load.
*   **Interface:** Exposes a Memory Mapped Slave interface to the HPS (ARM) and C64 Core.

### Memory Map (Avalon-MM Slave)
| Offset | Name | R/W | Description |
| :--- | :--- | :--- | :--- |
| `0x00` | `DATA_LEDS` | RW | 22-bit Data Paths (Address/Data display) |
| `0x04` | `STATUS_LEDS` | RW | Status indicators (Run, Pause, Master, etc.) |
| `0x08` | `SWITCH_STATE` | R | Current state of toggle switches |
| `0x0C` | `CONTROL` | RW | Bit 0: Enable, Bit 1: Mode (PDP11/C64) |

## 4. Software Integration (SIMH)
The PDP-11 emulator (SIMH) running on the ARM Linux side needs to communicate with the FPGA driver.

*   **Current PiDP-11 Logic:** SIMH calls a C function that bit-bangs GPIOs.
*   **SuperCPU Logic:**
    *   We modify the SIMH front panel driver to simply write the `PC` (Program Counter) and `Register` values to the memory-mapped FPGA addresses (`0xFF2000xx`).
    *   **Benefit:** Extremely low CPU overhead. The ARM CPU is free to run the emulation at maximum speed.

## 5. The "Super Integration" (C64 Dual Mode)
Since the FPGA controls the panel, we can repurpose the switches and lights when the PDP-11 emulator is **not** running, or even while it runs in the background.

### C64 Mode Features
When the user is working in C64 mode, the panel becomes a **Hardware Monitor**:

*   **Address LEDs:** Display the C64's Address Bus in real-time.
*   **Data LEDs:** Display the Data Bus or specific register values (e.g., SID voices).
*   **Switches as Controls:**
    *   **Switch 0-2:** Select Turbo Speed (1MHz, 20MHz, Max).
    *   **Switch 3:** Toggle JiffyDOS / Stock Kernal.
    *   **Switch 4:** Force Reset.
    *   **Switch 15:** "Mainframe Call" (Launches the PDP-11 Terminal on the C64 screen).

## 6. Implementation Steps
1.  **Hardware:** Design/Build the GPIO Pin Adapter.
2.  **FPGA:** Write `pidp11_driver.v` and integrate into Quartus project.
3.  **Linux:** Write a kernel module or `mmap` tool to test the LEDs.
4.  **SIMH:** Patch the PiDP-11 version of SIMH to use the FPGA memory map.
5.  **C64 Core:** Wire the C64 bus signals to the `pidp11_driver` for the "Dual Mode" features.
