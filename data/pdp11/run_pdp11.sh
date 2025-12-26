#!/bin/bash

# PDP-11 Launcher for SuperCPU
# Usage: ./run_pdp11.sh [system_name]
# Example: ./run_pdp11.sh rsts

PDP_DIR="$(dirname "$0")"
SYSTEMS_DIR="$PDP_DIR/systems"
DEFAULT_SYSTEM="rsts"

# 1. Determine System to Boot
TARGET_SYSTEM="${1:-$DEFAULT_SYSTEM}"
BOOT_INI="$SYSTEMS_DIR/$TARGET_SYSTEM/boot.ini"

echo "SuperCPU Mainframe Launcher"
echo "Target System: $TARGET_SYSTEM"

# 2. Check for SIMH
if ! command -v pdp11 &> /dev/null; then
    echo "Error: 'pdp11' (SIMH) is not installed."
    exit 1
fi

# 3. Check for Boot Configuration
if [ ! -f "$BOOT_INI" ]; then
    echo "Error: Configuration not found at $BOOT_INI"
    echo "Available Systems:"
    ls "$SYSTEMS_DIR" 2>/dev/null || echo "  (None found in $SYSTEMS_DIR)"
    exit 1
fi

# 4. Run the Simulator
# We change directory to the system folder so relative paths in boot.ini work
cd "$SYSTEMS_DIR/$TARGET_SYSTEM"
exec pdp11 boot.ini
