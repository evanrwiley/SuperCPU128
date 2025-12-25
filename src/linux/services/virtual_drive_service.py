import os
import time
import struct
import subprocess
from fpga_interface import FpgaInterface
from config_manager import ConfigManager
from library_manager import LibraryManager

# Virtual Drive Configuration
# Maps a Linux directory to a C64 Device ID (e.g., 10)

class VirtualDriveService:
    def __init__(self):
        self.config = ConfigManager()
        self.fpga = FpgaInterface()
        self.library = LibraryManager()
        self.drives = {} # Map device_id -> path or object
        
        self.setup_drives()
        print(f"[Drive] Service Started. Active Drives: {list(self.drives.keys())}")

    def setup_drives(self):
        drive_configs = self.config.get('drives', [])
        for d in drive_configs:
            if not d.get('enabled', True):
                continue
                
            dev_id = d['device_id']
            dtype = d['type']
            
            if dtype == 'local':
                path = d['path']
                if not os.path.exists(path):
                    try:
                        os.makedirs(path)
                    except:
                        print(f"[Drive] Failed to create local path {path}")
                        continue
                self.drives[dev_id] = {'type': 'local', 'path': path}
                
            elif dtype == 'library':
                # Special Library Drive
                self.drives[dev_id] = {'type': 'library', 'path': '//LIB'}

            elif dtype == 'smb':
                # Mount SMB share
                mount_point = f"/mnt/c64_drive_{dev_id}"
                if not os.path.exists(mount_point):
                    os.makedirs(mount_point)
                
                # Construct mount command
                # mount -t cifs //host/share /mnt/point -o user=u,password=p
                host = d['host']
                share = d['share']
                opts = f"user={d.get('user','guest')}"
                if d.get('password'):
                    opts += f",password={d['password']}"
                
                cmd = ["mount", "-t", "cifs", f"//{host}/{share}", mount_point, "-o", opts]
                
                try:
                    # Check if already mounted
                    if not os.path.ismount(mount_point):
                        print(f"[Drive] Mounting SMB: //{host}/{share} -> {mount_point}")
                        subprocess.check_call(cmd)
                    self.drives[dev_id] = mount_point
                except Exception as e:
                    print(f"[Drive] Failed to mount SMB {dev_id}: {e}")

    def list_directory(self, device_id):
        """Generates a C64-style directory listing"""
        if device_id not in self.drives:
            return "DEVICE NOT PRESENT"
            
        drive_obj = self.drives[device_id]
        
        # Handle Library Drive
        if drive_obj['type'] == 'library':
            return self._list_library(drive_obj['path'])
            
        # Handle Local/SMB Drive
        current_dir = drive_obj['path']
        try:
            files = os.listdir(current_dir)
            # Format: 0 "DISK NAME" ID 2A
            # Then lines: BLOCKS "FILENAME" TYPE
            listing = []
            listing.append(f'0 "NETWORK DRIVE" {device_id} 2A')
            
            for f in files:
                path = os.path.join(current_dir, f)
                size_blocks = os.path.getsize(path) // 254 # Approx blocks
                if os.path.isdir(path):
                    file_type = "DIR"
                else:
                    file_type = "PRG" # Default
                
                listing.append(f'{size_blocks:<4} "{f}" {file_type}')
            
            listing.append("0 BLOCKS FREE.")
            return "\r".join(listing)
        except Exception as e:
            return f"ERROR: {e}"

    def _list_library(self, vfs_path):
        """Generate listing from Library Manager"""
        items = self.library.get_virtual_listing(vfs_path)
        
        listing = []
        listing.append(f'0 "LIBRARY" 00 2A')
        
        # Add ".." if not root
        if vfs_path != "//LIB":
             listing.append(f'0    ".." DIR')

        for type_str, name, id_or_val in items:
            # If it's a file (PRG), we might want to show ID or something
            # But C64 directory is just Name + Type.
            # We need a way to map "LOAD name" back to the ID.
            # For now, just list them.
            listing.append(f'1    "{name}" {type_str}')
            
        listing.append("0 BLOCKS FREE.")
        return "\r".join(listing)

    def run(self):
        # Placeholder loop. 
        while True:
            # TODO: Check FPGA for Drive Commands (OPEN, LOAD, SAVE, CLOSE)
            time.sleep(1)

if __name__ == "__main__":
    drive = VirtualDriveService()
    drive.run()
