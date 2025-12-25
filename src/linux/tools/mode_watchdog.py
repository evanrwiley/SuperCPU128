#!/usr/bin/env python3
import time
import subprocess
import sys

# Constants
REG_STATUS = 0xD074
REG_FREQ_LO = 0xD075

# Tools
PEEK_TOOL = "src/linux/tools/peek"

def read_register(addr):
    try:
        result = subprocess.check_output([PEEK_TOOL, hex(addr)], stderr=subprocess.STDOUT)
        return int(result.strip(), 0)
    except:
        return 0

def monitor_mode():
    print("Starting C64/C128 Mode Watchdog...")
    
    last_mode = "UNKNOWN"
    
    while True:
        # Read Status Register
        status = read_register(REG_STATUS)
        
        # Bit 0: Reset Line (0=Resetting)
        rst_n = status & 0x01
        
        # Bit 1: C128 Mode (1=C128, 0=C64)
        is_c128 = (status & 0x02) >> 1
        
        current_mode = "C128" if is_c128 else "C64"
        
        if rst_n == 0:
            print("[EVENT] System Reset Detected!")
            # Wait for reset to release
            while (read_register(REG_STATUS) & 0x01) == 0:
                time.sleep(0.1)
            print("[EVENT] System Reset Released. Re-detecting...")
            last_mode = "RESET"
            continue
            
        if current_mode != last_mode:
            print(f"[CHANGE] Mode Switched: {last_mode} -> {current_mode}")
            # TODO: Load specific JSON config for this mode?
            # e.g. load_config(f"config/{current_mode.lower()}.json")
            last_mode = current_mode
            
        time.sleep(1)

if __name__ == "__main__":
    monitor_mode()
