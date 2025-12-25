import mmap
import os
import struct
import time

# Constants for FPGA Bridge (Base Address depends on Quartus project, assuming 0xFF200000 for Lightweight HPS-to-FPGA bridge)
LWHPS2FPGA_BASE = 0xFF200000
LWHPS2FPGA_SPAN = 0x00200000

# Heavyweight HPS-to-FPGA Bridge (For High Speed Memory Access)
# Assuming mapped to 0xC0000000 in Quartus
HPS2FPGA_BASE = 0xC0000000
HPS2FPGA_SPAN = 0x04000000 # 64MB Window (Covering 16MB REU)

# Debug Bridge Offsets (Hypothetical - Must match Qsys/Platform Designer)
DBG_CMD_VALID = 0x00020000  # Write 1 to start
DBG_CMD_TYPE  = 0x00020004  # 0=Read, 1=Write, 2=Halt, 3=Resume
DBG_CMD_ADDR  = 0x00020008  # 24-bit Address
DBG_CMD_WDATA = 0x0002000C  # 8-bit Write Data
DBG_CMD_RDATA = 0x00020010  # 8-bit Read Data (Valid when Done)
DBG_CMD_DONE  = 0x00020014  # Read 1 when complete

# Offsets for our UART Emulation (Defined in Qsys/Platform Designer)
# These are hypothetical offsets relative to the bridge base
UART_RX_FIFO_DATA = 0x00010000  # Write here to send data TO C64
UART_RX_FIFO_STATUS = 0x00010004 # Read to check if we can write (Full/Empty)
UART_TX_FIFO_DATA = 0x00010008  # Read here to get data FROM C64
UART_TX_FIFO_STATUS = 0x0001000C # Read to check if there is data (Valid/Empty)

class FpgaInterface:
    def __init__(self):
        self.mem = None
        self.mem_heavy = None
        try:
            self.fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
            self.mem = mmap.mmap(self.fd, LWHPS2FPGA_SPAN, offset=LWHPS2FPGA_BASE)
            
            # Try to map Heavyweight bridge for REU access
            try:
                self.mem_heavy = mmap.mmap(self.fd, HPS2FPGA_SPAN, offset=HPS2FPGA_BASE)
            except Exception as e:
                print(f"[FPGA] Warning: Could not map HPS2FPGA bridge. Fast memory access disabled. {e}")
                
        except Exception as e:
            print(f"[FPGA] Warning: Could not open /dev/mem. Running in simulation/mock mode. {e}")

    def write_rx_fifo(self, byte_val):
        """Send a byte TO the C64 (into the FPGA's RX FIFO)"""
        if self.mem:
            # Check if FIFO is full (Bit 0 of status)
            status = struct.unpack('<I', self.mem[UART_RX_FIFO_STATUS:UART_RX_FIFO_STATUS+4])[0]
            if not (status & 0x01): # Assuming bit 0 is FULL
                self.mem[UART_RX_FIFO_DATA:UART_RX_FIFO_DATA+4] = struct.pack('<I', byte_val)
                return True
        return False

    def read_tx_fifo(self):
        """Read a byte FROM the C64 (from the FPGA's TX FIFO)"""
        if self.mem:
            # Check if data is valid (Bit 0 of status)
            status = struct.unpack('<I', self.mem[UART_TX_FIFO_STATUS:UART_TX_FIFO_STATUS+4])[0]
           self.mem_heavy:
            self.mem_heavy.close()
        if  if status & 0x01: # Assuming bit 0 is VALID/NOT EMPTY
                data = struct.unpack('<I', self.mem[UART_TX_FIFO_DATA:UART_TX_FIFO_DATA+4])[0]
                return data & 0xFF
        return None

    def close(self):
        if self.mem:
            self.mem.close()
        if hasattr(self, 'fd'):
            os.close(self.fd)

    # --------------------------------------------------------------------------
    # Debug Bridge / Memory Access
    # --------------------------------------------------------------------------
    def debug_wait_done(self, timeout=1.0):
        """Wait for the debug command to complete"""
        if not self.mem: return False
        start = time.time()
        while True:
            done = struct.unpack('<I', self.mem[DBG_CMD_DONE:DBG_CMD_DONE+4])[0]
            if done & 0x01:
                return True
            if time.time() - start > timeout:
                print("[FPGA] Debug Bridge Timeout")
                return False
            # time.sleep(0.0001) # Busy wait for speed

    def peek(self, address):
        """Read a byte from SuperCPU memory"""
        if not self.mem: return 0
        
        # Setup Command
        self.mem[DBG_CMD_TYPE:DBG_CMD_TYPE+4] = struct.pack('<I', 0) # Read
        self.mem[DBG_CMD_ADDR:DBG_CMD_ADDR+4] = struct.pack('<I', address)
        
        # Trigger
        self.mem[DBG_CMD_VALID:DBG_CMD_VALID+4] = struct.pack('<I', 1)
        self.mem[DBG_CMD_VALID:DBG_CMD_VALID+4] = struct.pack('<I', 0) # Pulse? Or just edge? Assuming level for now, but usually pulse.
        
        if self.debug_wait_done():
            val = struct.unpack('<I', self.mem[DBG_CMD_RDATA:DBG_CMD_RDATA+4])[0]
            return val & 0xFF
        return 0

    def poke(self, address, data):
        """Write a byte to SuperCPU memory"""
        if not self.mem: return
        
        # Setup Command
        self.mem[DBG_CMD_TYPE:DBG_CMD_TYPE+4] = struct.pack('<I', 1) # Write
        self.mem[DBG_CMD_ADDR:DBG"""
        # Use Heavyweight bridge if available and address is within range
        if self.mem_heavy and address < HPS2FPGA_SPAN:
            if address + length <= HPS2FPGA_SPAN:
                return self.mem_heavy[address:address+length]
        
        # Fallback to slow peek
        data = bytearray(length)
        for i in range(length):
            data[i] = self.peek(address + i)
        return data

    def write_block(self, address, data):
        """Write a block of memory"""
        length = len(data)
        # Use Heavyweight bridge if available
        if self.mem_heavy and address < HPS2FPGA_SPAN:
            if address + length <= HPS2FPGA_SPAN:
                self.mem_heavy[address:address+length] = data
                return

        # Fallback to slow poke

    def read_block(self, address, length):
        """Read a block of memory (Slow byte-by-byte for now)"""
        data = bytearray(length)
        for i in range(length):
            data[i] = self.peek(address + i)
        return data

    def write_block(self, address, data):
        """Write a block of memory"""
        for i, byte in enumerate(data):
            self.poke(address + i, byte)
