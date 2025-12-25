import mmap
import os
import struct

# Constants for FPGA Bridge (Base Address depends on Quartus project, assuming 0xFF200000 for Lightweight HPS-to-FPGA bridge)
LWHPS2FPGA_BASE = 0xFF200000
LWHPS2FPGA_SPAN = 0x00200000

# Offsets for our UART Emulation (Defined in Qsys/Platform Designer)
# These are hypothetical offsets relative to the bridge base
UART_RX_FIFO_DATA = 0x00010000  # Write here to send data TO C64
UART_RX_FIFO_STATUS = 0x00010004 # Read to check if we can write (Full/Empty)
UART_TX_FIFO_DATA = 0x00010008  # Read here to get data FROM C64
UART_TX_FIFO_STATUS = 0x0001000C # Read to check if there is data (Valid/Empty)

class FpgaInterface:
    def __init__(self):
        self.mem = None
        try:
            self.fd = os.open("/dev/mem", os.O_RDWR | os.O_SYNC)
            self.mem = mmap.mmap(self.fd, LWHPS2FPGA_SPAN, offset=LWHPS2FPGA_BASE)
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
            if status & 0x01: # Assuming bit 0 is VALID/NOT EMPTY
                data = struct.unpack('<I', self.mem[UART_TX_FIFO_DATA:UART_TX_FIFO_DATA+4])[0]
                return data & 0xFF
        return None

    def close(self):
        if self.mem:
            self.mem.close()
        if hasattr(self, 'fd'):
            os.close(self.fd)
