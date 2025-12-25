import json
import os
import logging

CONFIG_PATH = os.path.join(os.path.dirname(__file__), '../../config.json')

DEFAULT_CONFIG = {
    "network": {
        "wifi_ssid": "",
        "wifi_psk": ""
    },
    "zimodem": {
        "port": 6400,
        "enabled": True
    },
    "drives": [
        {
            "device_id": 9,
            "type": "local",
            "path": "/home/root/c64_files",
            "enabled": True
        }
    ]
}

class ConfigManager:
    def __init__(self):
        self.config = DEFAULT_CONFIG
        self.load()

    def load(self):
        if os.path.exists(CONFIG_PATH):
            try:
                with open(CONFIG_PATH, 'r') as f:
                    loaded = json.load(f)
                    # Merge with default to ensure all keys exist
                    self.merge_config(self.config, loaded)
            except Exception as e:
                logging.error(f"Failed to load config: {e}")
        else:
            self.save() # Create default

    def merge_config(self, default, loaded):
        for key, value in loaded.items():
            if key in default and isinstance(default[key], dict) and isinstance(value, dict):
                self.merge_config(default[key], value)
            else:
                default[key] = value

    def save(self):
        try:
            with open(CONFIG_PATH, 'w') as f:
                json.dump(self.config, f, indent=4)
            return True
        except Exception as e:
            logging.error(f"Failed to save config: {e}")
            return False

    def get(self, key, default=None):
        return self.config.get(key, default)

    def set(self, key, value):
        self.config[key] = value
        self.save()

    def add_drive(self, drive_config):
        # Remove existing drive with same ID
        self.config['drives'] = [d for d in self.config['drives'] if d['device_id'] != drive_config['device_id']]
        self.config['drives'].append(drive_config)
        self.save()

    def remove_drive(self, device_id):
        self.config['drives'] = [d for d in self.config['drives'] if d['device_id'] != device_id]
        self.save()
