import logging

# Memory Map Constants
# -----------------------------------------------------------------------------

# C64 Safe Zones
C64_CASSETTE_BUFFER = {"name": "Cassette Buffer", "start": 0x033C, "end": 0x03FB, "size": 191}
C64_FREE_RAM_TOP    = {"name": "Top of Basic",    "start": 0xC000, "end": 0xCFFF, "size": 4096} # Often free, but used by some software
C64_IO_AREA_RAM     = {"name": "RAM under I/O",   "start": 0xD000, "end": 0xDFFF, "size": 4096} # Requires banking $01

# C128 Safe Zones
C128_CASSETTE_BUFFER = {"name": "Cassette Buffer", "start": 0x033C, "end": 0x03FB, "size": 191}
C128_FREE_RAM_BANK1  = {"name": "Bank 1 Free",     "start": 0x1300, "end": 0x1BFF, "size": 2304} # Often free in C128 mode

class SmartMemoryMap:
    def __init__(self):
        self.current_mode = "C64" # Default
        self.active_allocation = None
        self.logger = logging.getLogger("SmartMem")
        self.logger.setLevel(logging.INFO)

    def set_mode(self, mode):
        """
        Updates the system mode (C64, C128, C64_GO64).
        Triggered by the Watchdog service.
        """
        if mode != self.current_mode:
            self.logger.info(f"Mode switch detected: {self.current_mode} -> {mode}")
            self.current_mode = mode
            self.recalculate_allocation()

    def recalculate_allocation(self):
        """
        Decides the best memory location for the Bridge Window based on current mode.
        """
        # Default strategy: Try to use Cassette Buffer first (least intrusive)
        # If we need more space, we might need to negotiate or use upper RAM.
        
        new_allocation = None

        if "C64" in self.current_mode:
            # In C64 mode (or GO64), Cassette buffer is usually safe
            new_allocation = C64_CASSETTE_BUFFER
        elif "C128" in self.current_mode:
            # In C128 mode, Cassette buffer is also usually safe
            new_allocation = C128_CASSETTE_BUFFER
        
        if new_allocation != self.active_allocation:
            self.active_allocation = new_allocation
            self.apply_allocation(new_allocation)

    def apply_allocation(self, allocation):
        """
        Configures the FPGA to map the Bridge Window to the chosen address.
        """
        if allocation:
            self.logger.info(f"Allocating Bridge Window to: {allocation['name']} (${allocation['start']:04X}-${allocation['end']:04X})")
            
            # TODO: Write to FPGA Control Registers via FpgaInterface
            # self.fpga.write_register(REG_BRIDGE_WINDOW_BASE, allocation['start'])
            # self.fpga.write_register(REG_BRIDGE_WINDOW_ENABLE, 1)
            pass

    def get_current_allocation(self):
        return self.active_allocation

    def suggest_hidden_ram_strategy(self):
        """
        Returns instructions on how to access hidden RAM for the current mode.
        """
        if "C64" in self.current_mode:
            return {
                "strategy": "Bank Switching",
                "register": 0x01,
                "value_map": {
                    "All RAM": 0x30, # %00110000 - RAM in D000-DFFF, E000-FFFF
                    "IO Only": 0x35, # %00110101 - Default
                    "Kernal Off": 0x36 # %00110110 - I/O on, Kernal off (RAM under Kernal)
                }
            }
        return None

if __name__ == "__main__":
    # Test Stub
    logging.basicConfig()
    sm = SmartMemoryMap()
    sm.set_mode("C64")
    print(f"Current Allocation: {sm.get_current_allocation()}")
    sm.set_mode("C128")
    print(f"Current Allocation: {sm.get_current_allocation()}")
