import os
import logging
import shutil
import json
from config_manager import ConfigManager
from fpga_interface import FpgaInterface

# Paths
DIAG_ROM_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../data/diagnostics'))

class DiagnosticsManager:
    def __init__(self):
        self.config = ConfigManager()
        self.fpga = FpgaInterface()
        self.logger = logging.getLogger("DiagnosticsManager")
        self._ensure_paths()
        self.metadata = self._load_metadata()

    def _ensure_paths(self):
        if not os.path.exists(DIAG_ROM_PATH):
            os.makedirs(DIAG_ROM_PATH)

    def _load_metadata(self):
        meta_path = os.path.join(DIAG_ROM_PATH, 'metadata.json')
        if os.path.exists(meta_path):
            try:
                with open(meta_path, 'r') as f:
                    return json.load(f)
            except Exception as e:
                self.logger.error(f"Failed to load metadata: {e}")
                return {}
        return {}

    def list_diagnostics(self):
        """List available diagnostic ROMs with metadata"""
        roms = []
        if os.path.exists(DIAG_ROM_PATH):
            for f in os.listdir(DIAG_ROM_PATH):
                if f.lower().endswith(('.bin', '.crt')):
                    meta = self.metadata.get(f, {})
                    roms.append({
                        'filename': f,
                        'title': meta.get('title', f),
                        'description': meta.get('description', 'No description available.'),
                        'system': meta.get('system', 'Unknown')
                    })
        return sorted(roms, key=lambda x: x['title'])

    def install_diagnostic(self, source_path):
        """Install a diagnostic ROM from an external source"""
        try:
            filename = os.path.basename(source_path)
            dest = os.path.join(DIAG_ROM_PATH, filename)
            shutil.copy2(source_path, dest)
            self.logger.info(f"Installed diagnostic: {filename}")
            return True
        except Exception as e:
            self.logger.error(f"Failed to install diagnostic: {e}")
            return False

    def run_diagnostic(self, filename, mode="C64"):
        """
        Load and run a diagnostic ROM.
        filename: name of the file in the diagnostics directory
        mode: "C64" or "C128" (Determines cartridge mode)
        """
        path = os.path.join(DIAG_ROM_PATH, filename)
        
        if not os.path.exists(path):
            self.logger.error(f"Diagnostic file not found: {path}")
            return False

        self.logger.info(f"Loading diagnostic {filename} in {mode} mode...")

        try:
            with open(path, 'rb') as f:
                data = f.read()

            # 1. Determine Cartridge Type based on file size or header
            # Standard C64 Diag is 8KB at $8000 (EXROM=0, GAME=1)
            # Dead Test is 8KB at $E000 (Ultimax: EXROM=0, GAME=0)
            
            size = len(data)
            cart_config = {
                "exrom": 1,
                "game": 1,
                "address": 0x8000,
                "bank": 0
            }

            if "dead" in filename.lower() or "ultimax" in filename.lower():
                # Dead Test / Ultimax
                cart_config["exrom"] = 0
                cart_config["game"] = 0
                cart_config["address"] = 0xE000 # Ultimax maps ROML to E000
            elif size == 8192:
                # Standard 8K Cart
                cart_config["exrom"] = 0
                cart_config["game"] = 1
                cart_config["address"] = 0x8000
            elif size == 16384:
                # 16K Cart
                cart_config["exrom"] = 0
                cart_config["game"] = 0
                cart_config["address"] = 0x8000 # Lo at 8000, Hi at A000 or E000 depending on mode
            
            # 2. Write ROM to FPGA Memory (Shadow RAM for ROM emulation)
            # We need a specific area in the FPGA memory map for "Cartridge ROM"
            # Let's assume 0x100000 (1MB mark) is reserved for Cart ROMs in our map
            CART_ROM_BASE = 0x100000 
            self.fpga.write_block(CART_ROM_BASE, data)

            # 3. Configure FPGA Cartridge Emulation Registers
            # We need to tell the FPGA to assert EXROM/GAME and map the ROM
            # Hypothetical Registers:
            # REG_CART_CTRL (Offset 0x40): Bit 0=Enable, Bit 1=EXROM, Bit 2=GAME
            # REG_CART_ADDR (Offset 0x44): Base address in SDRAM
            
            # Invert signals (Active Low on bus, but usually 0=Active in logic)
            # Let's assume our register expects 0 for Active (Low)
            ctrl_val = 0
            if cart_config["exrom"] == 0: ctrl_val |= (1 << 1) # Set bit to pull low? Or 0 to pull low?
            # Let's stick to: 1 = Force Low (Active), 0 = High (Inactive)
            
            # Actually, let's define the register bits clearly:
            # Bit 0: Override Enable
            # Bit 1: EXROM_N Level (0=Low/Active, 1=High/Inactive)
            # Bit 2: GAME_N Level (0=Low/Active, 1=High/Inactive)
            # Bit 3: Swap 8K/16K Mode
            
            reg_val = 1 # Enable Override
            if cart_config["exrom"] == 0: reg_val &= ~(1 << 1) # 0 = Active
            else: reg_val |= (1 << 1)
            
            if cart_config["game"] == 0: reg_val &= ~(1 << 2)
            else: reg_val |= (1 << 2)

            # Write Config
            # self.fpga.write_register(0x40, reg_val) 
            # self.fpga.write_register(0x44, CART_ROM_BASE)
            
            # For now, we log what we would do
            self.logger.info(f"FPGA Config: EXROM={cart_config['exrom']}, GAME={cart_config['game']}")
            
            # 4. Trigger Reset
            # self.fpga.trigger_reset()
            
            return True

        except Exception as e:
            self.logger.error(f"Failed to run diagnostic: {e}")
            return False

