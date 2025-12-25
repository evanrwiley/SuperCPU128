#!/usr/bin/env python3
import subprocess
import sys
import time

# Path to the low-level peek tool
PEEK_TOOL = "src/linux/tools/peek"

def peek(addr):
    """Reads a byte from the C64/C128 bus via the FPGA."""
    try:
        # The peek tool likely takes an address in hex or decimal
        # Usage: peek <address>
        result = subprocess.check_output([PEEK_TOOL, hex(addr)], stderr=subprocess.STDOUT)
        # Parse output (assuming it returns "0xXX" or similar)
        return int(result.strip(), 0)
    except Exception as e:
        # print(f"Error reading address {hex(addr)}: {e}")
        return None

def read_rom_string(start_addr, length):
    """Reads a sequence of bytes and converts to ASCII."""
    chars = []
    for i in range(length):
        val = peek(start_addr + i)
        if val is not None:
            chars.append(chr(val))
        else:
            return None
    return "".join(chars)

def detect_system():
    print("Detecting System Type...")
    
    # Method 1: Check for C64 Kernal Signature
    # "COMMODORE 64" is usually at $E47C (decimal 58492) in C64 Kernal
    # Let's check a few bytes
    sig_c64 = read_rom_string(0xE47C, 9)
    
    # Method 2: Check for C128 Kernal Signature
    # C128 Kernal usually has "CBM" at $FF80 or similar version info
    # Or check $C000 area if mapped.
    # A reliable C128 check is the MMU at $D500, but that's I/O.
    # Let's check the Reset Vector $FFFC
    reset_lo = peek(0xFFFC)
    reset_hi = peek(0xFFFD)
    
    if reset_lo is None or reset_hi is None:
        print("Error: Unable to read Bus. Is the FPGA configured?")
        return "UNKNOWN"

    reset_vec = (reset_hi << 8) | reset_lo
    print(f"  - Reset Vector: {hex(reset_vec)}")
    
    # Heuristic Identification
    system_type = "UNKNOWN"
    
    if sig_c64 == "COMMODORE":
        # It's a C64 (or C128 in C64 mode)
        # To distinguish C128-in-C64-mode from Real C64, we might check $D030
        # But for now, let's call it C64 Mode.
        system_type = "C64"
        
        # Advanced Check: Try to read $D030 (C128 2MHz register)
        # On C64, this is usually open bus or mirror.
        # On C128 (even in C64 mode?), it might be accessible? 
        # Actually, in C64 mode, C128 hides most things.
        
    else:
        # Check for C128 specific markers
        # C128 Kernal often has entry points different from C64
        # Let's assume if it's not C64, it might be C128
        system_type = "C128"

    print(f"  - Detected System: {system_type}")
    return system_type

if __name__ == "__main__":
    detect_system()
