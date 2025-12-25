#!/usr/bin/env python3
import time
import subprocess
import sys
import os

# Add services directory to path
sys.path.append(os.path.join(os.path.dirname(__file__), '../services'))

from system_map import SystemMap
from smart_memory_map import SmartMemoryMap

# Tools
PEEK_TOOL = "src/linux/tools/peek"
POKE_TOOL = "src/linux/tools/poke"

def peek(addr):
    try:
        result = subprocess.check_output([PEEK_TOOL, hex(addr)], stderr=subprocess.STDOUT)
        return int(result.strip(), 0)
    except:
        return None

def poke(addr, val):
    try:
        subprocess.check_call([POKE_TOOL, hex(addr), hex(val)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except:
        return False

class Watchdog:
    def __init__(self):
        self.current_mode = "UNKNOWN"
        self.last_freq = 0
        self.memory_map = SmartMemoryMap()

    def get_frequency(self):
        # Read 32-bit frequency from FPGA registers $D075-$D078
        f0 = peek(SystemMap.SCPU["REG_FREQ"])
        f1 = peek(SystemMap.SCPU["REG_FREQ"] + 1)
        f2 = peek(SystemMap.SCPU["REG_FREQ"] + 2)
        f3 = peek(SystemMap.SCPU["REG_FREQ"] + 3)
        
        if f0 is None: return 0
        return f0 | (f1 << 8) | (f2 << 16) | (f3 << 24)

    def detect_mode(self):
        freq = self.get_frequency()
        self.last_freq = freq
        
        # 1. Check Hardware Reset Status
        status = peek(SystemMap.SCPU["REG_STATUS"])
        if status is not None and (status & 0x01) == 0:
            return "RESETTING"

        # 2. Frequency Analysis
        if freq > 1500000: # > 1.5MHz
            # Likely C128 Fast Mode (2MHz) or SuperCPU Turbo (20MHz)
            # To be sure it's C128, we can try to read the MMU
            if self.check_c128_mmu():
                return "C128"
            else:
                # High speed but no MMU? Could be C64 with Turbo enabled?
                # Or just C128 with MMU hidden (unlikely in 2MHz mode)
                return "C128" # Assume C128 for now if fast
        
        elif freq > 500000: # > 0.5MHz (approx 1MHz)
            # Could be C64 or C128 Slow Mode
            if self.check_c128_mmu():
                return "C128_SLOW"
            else:
                return "C64"
        
        else:
            return "HALTED" # or Z80?

    def check_c128_mmu(self):
        # Try to read MMU Configuration Register at $D500
        # In C64 mode, this is usually open bus or I/O noise.
        # In C128 mode, it returns the configuration.
        # A safe check is to read, write a bit, read back, restore.
        # BUT, writing MMU is dangerous.
        # Safer: Check if $D030 (Test Register) is visible?
        # Let's just try to read $D505 (Mode Config)
        val = peek(SystemMap.C128["MMU_MODE"])
        if val is not None and (val & 0xF0) == 0x40: # Example check (needs verification)
             # This is heuristic. A better way is checking ROM signature if mapped.
             return True
        
        # Fallback: Check ROM at $FF80 (C128 Kernal Entry)
        # C64 has Kernal there too, but bytes differ.
        return False

    def run(self):
        print("Starting Robust Watchdog Service...")
        while True:
            new_mode = self.detect_mode()
            
            if new_mode != self.current_mode:
                print(f"[MODE CHANGE] {self.current_mode} -> {new_mode} (Freq: {self.last_freq} Hz)")
                self.current_mode = new_mode
                self.on_mode_change(new_mode)
            
            time.sleep(1)

    def on_mode_change(self, mode):
        # Configure system based on mode
        print(f"Configuring system for {mode}...")
        self.memory_map.set_mode(mode)
        
        # Example: If C128, maybe disable some C64-specific accelerators?
        if mode == "C128":
            pass
        if "C128" in mode:
            print("  -> Configuring for C128 Architecture")
            # Load C128 specific FPGA map?
        elif "C64" in mode:
            print("  -> Configuring for C64 Architecture")
        elif "RESETTING" in mode:
            print("  -> System is Resetting...")

if __name__ == "__main__":
    wd = Watchdog()
    wd.run()
