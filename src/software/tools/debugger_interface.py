import mmap
import os
import struct
import time

# Memory Map for Debug Bridge (as defined in debug_bridge.v)
# This needs to match the HPS-to-FPGA address mapping
BRIDGE_BASE = 0xFF200000 # Example Base Address (needs verification with Quartus project)
REG_CMD_TYPE  = 0x00
REG_CMD_ADDR  = 0x04
REG_CMD_WDATA = 0x08
REG_CMD_RDATA = 0x0C
REG_CMD_VALID = 0x10
REG_CMD_DONE  = 0x14
REG_CPU_HALT  = 0x18

class DebuggerInterface:
    def __init__(self):
        self.mem = None
        try:
            self.f = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
            self.mem = mmap.mmap(self.f, 4096, mmap.MAP_SHARED, mmap.PROT_READ | mmap.PROT_WRITE, offset=BRIDGE_BASE)
        except Exception as e:
            print(f"Warning: Could not open /dev/mem ({e}). Running in Mock Mode.")

    def _write_reg(self, offset, value):
        if self.mem:
            self.mem.seek(offset)
            self.mem.write(struct.pack('<I', value))

    def _read_reg(self, offset):
        if self.mem:
            self.mem.seek(offset)
            return struct.unpack('<I', self.mem.read(4))[0]
        return 0

    def halt_cpu(self):
        """Pauses the C64 CPU."""
        print("Halting CPU...")
        self._write_reg(REG_CMD_TYPE, 0x02) # Halt Command
        self._write_reg(REG_CMD_VALID, 1)
        self._wait_done()

    def resume_cpu(self):
        """Resumes the C64 CPU."""
        print("Resuming CPU...")
        self._write_reg(REG_CMD_TYPE, 0x03) # Resume Command
        self._write_reg(REG_CMD_VALID, 1)
        self._wait_done()

    def read_memory(self, address: int) -> int:
        """Reads a byte from C64 memory."""
        self._write_reg(REG_CMD_ADDR, address)
        self._write_reg(REG_CMD_TYPE, 0x00) # Read Command
        self._write_reg(REG_CMD_VALID, 1)
        self._wait_done()
        return self._read_reg(REG_CMD_RDATA) & 0xFF

    def write_memory(self, address: int, value: int):
        """Writes a byte to C64 memory."""
        self._write_reg(REG_CMD_ADDR, address)
        self._write_reg(REG_CMD_WDATA, value)
        self._write_reg(REG_CMD_TYPE, 0x01) # Write Command
        self._write_reg(REG_CMD_VALID, 1)
        self._wait_done()

    def _wait_done(self):
        if not self.mem: return
        timeout = 1000
        while self._read_reg(REG_CMD_DONE) == 0 and timeout > 0:
            timeout -= 1
        self._write_reg(REG_CMD_VALID, 0) # Clear valid

# Example Usage
if __name__ == "__main__":
    dbg = DebuggerInterface()
    dbg.halt_cpu()
    val = dbg.read_memory(0xD020) # Read Border Color
    print(f"Border Color: {val}")
    dbg.resume_cpu()
