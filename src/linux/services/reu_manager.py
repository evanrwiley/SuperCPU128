import os
import sys
import logging
from fpga_interface import FpgaInterface
from config_manager import ConfigManager

# REU Constants
REU_SIZE_512KB = 512 * 1024
REU_SIZE_16MB = 16 * 1024 * 1024
DEFAULT_REU_SIZE = REU_SIZE_512KB

class ReuManager:
    def __init__(self):
        self.config = ConfigManager()
        self.fpga = FpgaInterface()
        self.logger = logging.getLogger("ReuManager")
        
        # Ensure config has REU section
        if not self.config.get('reu'):
            self.config.set('reu', {
                'enabled': True,
                'size_mb': 0.5,
                'default_image': "",
                'autoload': False
            })

    def get_reu_size(self):
        size_mb = self.config.get('reu', {}).get('size_mb', 0.5)
        return int(size_mb * 1024 * 1024)

    def save_image(self, filename):
        """Save current REU memory to a file"""
        size = self.get_reu_size()
        self.logger.info(f"Saving REU image ({size} bytes) to {filename}...")
        
        try:
            # Read from FPGA (This might be slow byte-by-byte, optimization needed for production)
            # Ideally, we'd use a DMA engine or block transfer in the driver.
            data = self.fpga.read_block(0, size) # Assuming REU starts at 0 in SuperRAM
            
            with open(filename, 'wb') as f:
                f.write(data)
            
            self.logger.info("Save complete.")
            return True
        except Exception as e:
            self.logger.error(f"Failed to save REU image: {e}")
            return False

    def load_image(self, filename):
        """Load an REU image from a file into memory"""
        if not os.path.exists(filename):
            self.logger.error(f"File not found: {filename}")
            return False
            
        try:
            with open(filename, 'rb') as f:
                data = f.read()
            
            size = self.get_reu_size()
            if len(data) > size:
                self.logger.warning(f"Image size ({len(data)}) > REU size ({size}). Truncating.")
                data = data[:size]
            
            self.logger.info(f"Loading REU image ({len(data)} bytes) from {filename}...")
            self.fpga.write_block(0, data)
            self.logger.info("Load complete.")
            return True
        except Exception as e:
            self.logger.error(f"Failed to load REU image: {e}")
            return False

    def clear_memory(self):
        """Clear REU memory (fill with zeros)"""
        size = self.get_reu_size()
        self.logger.info(f"Clearing REU memory ({size} bytes)...")
        # Create a block of zeros
        zeros = bytearray(size) # Warning: This might be large for memory
        # Better to write in chunks
        chunk_size = 4096
        zeros_chunk = bytearray(chunk_size)
        
        for addr in range(0, size, chunk_size):
            # Handle last chunk
            current_chunk_size = min(chunk_size, size - addr)
            if current_chunk_size < chunk_size:
                self.fpga.write_block(addr, zeros_chunk[:current_chunk_size])
            else:
                self.fpga.write_block(addr, zeros_chunk)
                
        self.logger.info("Clear complete.")

    def set_autoload(self, filename, enable=True):
        """Set the default image and enable/disable autoload"""
        reu_config = self.config.get('reu', {})
        reu_config['default_image'] = filename
        reu_config['autoload'] = enable
        self.config.set('reu', reu_config)
        self.logger.info(f"Autoload set to {enable} with image {filename}")

    def check_autoload(self):
        """Called on startup to load the default image if enabled"""
        reu_config = self.config.get('reu', {})
        if reu_config.get('autoload') and reu_config.get('default_image'):
            image_path = reu_config['default_image']
            if os.path.exists(image_path):
                self.logger.info(f"Autoloading REU image: {image_path}")
                self.load_image(image_path)
            else:
                self.logger.error(f"Autoload failed: Image not found {image_path}")

if __name__ == "__main__":
    # Simple test
    logging.basicConfig(level=logging.INFO)
    mgr = ReuManager()
    # mgr.clear_memory()
