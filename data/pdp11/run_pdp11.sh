#!/bin/bash

# PDP-11 Launcher for SuperCPU
# This script is called by the ZiModem Bridge when the user dials "ATDT SIMH"

PDP_DIR="$(dirname "$0")"
cd "$PDP_DIR"

# Check if simh is installed
if ! command -v pdp11 &> /dev/null; then
    echo "Error: 'pdp11' (SIMH) is not installed."
    echo "Please install it via: sudo apt-get install simh"
    exit 1
fi

# Check for boot configuration
if [ ! -f "boot.ini" ]; then
    echo "Error: boot.ini not found in $PDP_DIR"
    echo "Please configure your PDP-11 environment."
    exit 1
fi

# Run the simulator
# We use -q for quiet startup if possible, but standard output is piped to C64
exec pdp11 boot.ini
