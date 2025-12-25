# C64/C128 System Memory Map & Constants
# Used by Linux tools to interact with the host machine robustly.

class SystemMap:
    # -------------------------------------------------------------------------
    # C64 Constants
    # -------------------------------------------------------------------------
    C64 = {
        "NAME": "C64",
        "KEY_BUFFER": 0x0277,      # Keyboard Buffer Start
        "KEY_COUNT": 0x00C6,       # Number of keys in buffer
        "SCREEN_RAM": 0x0400,      # Default Screen RAM
        "BASIC_START": 0x0801,     # Start of Basic
        "ROM_SIGNATURE_ADDR": 0xE47C,
        "ROM_SIGNATURE_TEXT": "COMMODORE"
    }

    # -------------------------------------------------------------------------
    # C128 Constants
    # -------------------------------------------------------------------------
    C128 = {
        "NAME": "C128",
        "KEY_BUFFER": 0x034A,      # Keyboard Buffer Start
        "KEY_COUNT": 0x00D0,       # Number of keys in buffer
        "SCREEN_RAM": 0x0400,      # Default Screen RAM (40 Col)
        "BASIC_START": 0x1C01,     # Start of Basic (Bank 1)
        "MMU_CONFIG": 0xD500,      # MMU Configuration Register
        "MMU_MODE": 0xD505,        # Mode Configuration Register
        "VDC_INDEX": 0xD600,       # VDC Address Register
        "VDC_DATA": 0xD601         # VDC Data Register
    }

    # -------------------------------------------------------------------------
    # SuperCPU Constants
    # -------------------------------------------------------------------------
    SCPU = {
        "REG_BASE": 0xD070,
        "REG_STATUS": 0xD074,      # Status (Reset/Mode)
        "REG_FREQ": 0xD075         # Frequency Counter
    }
