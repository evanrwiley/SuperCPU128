#!/usr/bin/env python3
import os
import sys
import subprocess

# Add services to path
sys.path.append(os.path.join(os.path.dirname(__file__), 'services'))
from config_manager import ConfigManager

class SetupWizard:
    def __init__(self):
        self.config = ConfigManager()
        self.clear_screen()

    def clear_screen(self):
        os.system('cls' if os.name == 'nt' else 'clear')

    def print_header(self):
        print("========================================")
        print("   SuperCPU C64/C128 Setup Wizard       ")
        print("========================================")
        print("")

    def main_menu(self):
        while True:
            self.clear_screen()
            self.print_header()
            print("1. Configure WiFi")
            print("2. Map Network Drive (SMB/Windows)")
            print("3. Map Local Directory")
            print("4. Configure BBS Server")
            print("5. View Current Configuration")
            print("6. Exit")
            print("")
            
            choice = input("Select an option (1-6): ")
            
            if choice == '1': self.configure_wifi()
            elif choice == '2': self.map_smb_drive()
            elif choice == '3': self.map_local_drive()
            elif choice == '4': self.configure_bbs()
            elif choice == '5': self.view_config()
            elif choice == '6': break

    def configure_wifi(self):
        self.clear_screen()
        print("--- Configure WiFi ---")
        ssid = input("Enter WiFi SSID: ")
        psk = input("Enter WiFi Password: ")
        
        if ssid:
            self.config.config['network']['wifi_ssid'] = ssid
            self.config.config['network']['wifi_psk'] = psk
            self.config.save()
            print("WiFi settings saved. (Note: Requires restart to apply)")
        input("Press Enter to continue...")

    def map_smb_drive(self):
        self.clear_screen()
        print("--- Map Network Drive (SMB/Windows Share) ---")
        print("This will map a shared folder from another computer to a C64 Device ID.")
        print("Note: Device 8 is usually reserved for a physical floppy drive.")
        
        try:
            device_id = int(input("Enter C64 Device ID (8-11) [Default 9]: ") or "9")
        except:
            print("Invalid ID.")
            return

        host = input("Server IP Address (e.g., 192.168.1.50): ")
        share = input("Share Name (e.g., c64files): ")
        user = input("Username (leave blank for guest): ")
        password = ""
        if user:
            password = input("Password: ")

        drive_config = {
            "device_id": device_id,
            "type": "smb",
            "host": host,
            "share": share,
            "user": user,
            "password": password,
            "enabled": True
        }
        
        self.config.add_drive(drive_config)
        print(f"Drive {device_id} mapped to \\\\{host}\\{share}")
        input("Press Enter to continue...")

    def map_local_drive(self):
        self.clear_screen()
        print("--- Map Local Directory ---")
        print("Note: Device 8 is usually reserved for a physical floppy drive.")
        
        try:
            device_id = int(input("Enter C64 Device ID (8-11) [Default 9]: ") or "9")
        except:
            print("Invalid ID.")
            return

        path = input("Enter Local Path (e.g., /home/root/c64): ")
        
        drive_config = {
            "device_id": device_id,
            "type": "local",
            "path": path,
            "enabled": True
        }
        
        self.config.add_drive(drive_config)
        print(f"Drive {device_id} mapped to {path}")
        input("Press Enter to continue...")

    def configure_bbs(self):
        self.clear_screen()
        print("--- Configure BBS Server ---")
        
        try:
            port = int(input("Enter Listening Port [Default 6400]: ") or "6400")
            enabled = input("Enable Server? (y/n) [y]: ").lower() != 'n'
        except:
            print("Invalid input.")
            return

        self.config.config['zimodem']['port'] = port
        self.config.config['zimodem']['enabled'] = enabled
        self.config.save()
        print("BBS Settings Saved.")
        input("Press Enter to continue...")

    def view_config(self):
        self.clear_screen()
        print("--- Current Configuration ---")
        print(json.dumps(self.config.config, indent=4))
        input("Press Enter to continue...")

if __name__ == "__main__":
    wizard = SetupWizard()
    wizard.main_menu()
