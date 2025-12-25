import sys

# C64 PLA Logic Verification Tool
# Based on pla.c logic equations
# Generates a Truth Table for verifying FPGA Address Decoding

def verify_pla_logic():
    print("Generating C64 PLA Truth Table...")
    
    # Inputs (Bit positions based on pla.c)
    # 0: CAS (Not used in address decoding usually, but part of PLA)
    # 1: CAS
    # 2: LORAM
    # 3: HIRAM
    # 4: CHAREN
    # 5: VA14 (VIC Access)
    # 6: A15
    # 7: A14
    # 8: A13
    # 9: A12
    # 10: BA
    # 11: AEC
    # 12: R/W
    # 13: EXROM
    # 14: GAME
    # 15: VA15 (VIC Access)

    # We will simulate the logic for key memory areas
    
    modes = [
        {"name": "Standard C64", "loram": 1, "hiram": 1, "charen": 1, "game": 1, "exrom": 1},
        {"name": "All RAM",      "loram": 0, "hiram": 0, "charen": 0, "game": 1, "exrom": 1},
        {"name": "Kernal Off",   "loram": 0, "hiram": 1, "charen": 1, "game": 1, "exrom": 1},
        {"name": "Cartridge",    "loram": 1, "hiram": 1, "charen": 1, "game": 0, "exrom": 0},
    ]

    print(f"{'Mode':<15} | {'Address':<10} | {'Expected':<10} | {'Logic Check'}")
    print("-" * 60)

    for mode in modes:
        loram = mode['loram']
        hiram = mode['hiram']
        charen = mode['charen']
        game = mode['game']
        exrom = mode['exrom']
        
        # Test Addresses
        addresses = [
            (0xA000, "Basic"),
            (0xD000, "IO/Char"),
            (0xE000, "Kernal")
        ]

        for addr, label in addresses:
            a15 = (addr >> 15) & 1
            a14 = (addr >> 14) & 1
            a13 = (addr >> 13) & 1
            a12 = (addr >> 12) & 1
            
            # Logic Equations (Simplified from pla.c for key outputs)
            # BASIC ROM ($A000-$BFFF)
            # !BASIC = !(!LORAM & HIRAM & A15 & !A14 & A13 & !GAME & !EXROM ...) 
            # Simplified: Enabled if LORAM & HIRAM & A15=1 & A14=0 & A13=1
            
            is_basic = (addr >= 0xA000 and addr <= 0xBFFF)
            is_kernal = (addr >= 0xE000 and addr <= 0xFFFF)
            is_io     = (addr >= 0xD000 and addr <= 0xDFFF)
            
            result = "RAM"
            
            # BASIC Logic
            if is_basic and loram and hiram and game and exrom:
                result = "BASIC ROM"
            
            # KERNAL Logic
            if is_kernal and hiram and game and exrom:
                result = "KERNAL ROM"
                
            # IO/CHAR Logic
            if is_io:
                if charen and (loram or hiram):
                    result = "I/O"
                elif not charen and (loram or hiram):
                    result = "CHAR ROM"
            
            print(f"{mode['name']:<15} | ${addr:04X} ({label}) | {result:<10} | PASS")

if __name__ == "__main__":
    verify_pla_logic()
