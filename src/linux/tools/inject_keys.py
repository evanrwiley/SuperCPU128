#!/usr/bin/env python3
import sys
import time
import subprocess
from system_map import SystemMap
from robust_watchdog import Watchdog

# Tools
POKE_TOOL = "src/linux/tools/poke"
PEEK_TOOL = "src/linux/tools/peek"

def poke(addr, val):
    subprocess.check_call([POKE_TOOL, hex(addr), hex(val)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def peek(addr):
    try:
        result = subprocess.check_output([PEEK_TOOL, hex(addr)], stderr=subprocess.STDOUT)
        return int(result.strip(), 0)
    except:
        return 0

class KeyInjector:
    def __init__(self):
        self.wd = Watchdog()
        # Run a single detection to get current state
        self.mode = self.wd.detect_mode()
        print(f"Detected System: {self.mode}")

    def type_string(self, text):
        """Injects a string into the keyboard buffer."""
        if "C128" in self.mode:
            buf_start = SystemMap.C128["KEY_BUFFER"]
            count_addr = SystemMap.C128["KEY_COUNT"]
            max_len = 10 # C128 buffer size
        else:
            buf_start = SystemMap.C64["KEY_BUFFER"]
            count_addr = SystemMap.C64["KEY_COUNT"]
            max_len = 10 # C64 buffer size

        # Convert text to PETSCII (Simplified - assumes uppercase/numbers match)
        # Real implementation needs a full ASCII->PETSCII table
        petscii_bytes = [ord(c.upper()) for c in text]
        petscii_bytes.append(13) # Add Return key

        # Injection Loop
        # We can only inject as many chars as the buffer holds (10).
        # For longer strings, we must wait for the buffer to empty.
        
        idx = 0
        while idx < len(petscii_bytes):
            # Check current buffer depth
            current_depth = peek(count_addr)
            
            if current_depth < max_len:
                # Write char to next slot
                char_to_write = petscii_bytes[idx]
                poke(buf_start + current_depth, char_to_write)
                
                # Increment count
                poke(count_addr, current_depth + 1)
                
                idx += 1
            else:
                # Buffer full, wait a bit
                time.sleep(0.05)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: inject_keys.py <text>")
        sys.exit(1)
    
    injector = KeyInjector()
    injector.type_string(" ".join(sys.argv[1:]))
