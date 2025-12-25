# PDP-11 Mainframe Environment

This directory contains the configuration and disk images for the PDP-11 emulation running on the SuperCPU's ARM processor.

## Setup Instructions

1.  **Install SIMH**:
    Ensure the SIMH simulator is installed on the Linux system:
    ```bash
    sudo apt-get update
    sudo apt-get install simh
    ```

2.  **Get OS Images**:
    Due to copyright, we cannot distribute the RSTS/E or UNIX disk images. You must provide your own.
    *   **RSTS/E V7.0** is a popular choice for a classic 1980s timesharing experience.
    *   **UNIX V7** is also historically significant.

3.  **Configuration**:
    Place your disk images (e.g., `rsts_v7.dsk`) in this directory.
    Create a `boot.ini` file to tell SIMH how to boot.

    **Example `boot.ini` for RSTS/E:**
    ```ini
    set cpu 11/70
    set cpu 2M
    set rq0 ra81
    att rq0 rsts_v7.dsk
    boot rq0
    ```

## Usage

From your C64/C128 terminal program (e.g., CCGMS):
1.  Type `ATDT SIMH`
2.  You will be connected to the PDP-11 console.
3.  To exit, use the SIMH escape command (usually `CTRL+E`) or hang up the modem (`+++` then `ATH`).
