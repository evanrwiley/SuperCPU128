#!/usr/bin/env python3
import json
import os
import sys

# Configuration File Path
CONFIG_FILE = "/etc/supercpu/config.json"
DEFAULT_CONFIG_FILE = "src/linux/config/supercpu_config.json"

def load_config(path):
    try:
        with open(path, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"Config file not found at {path}. Using defaults.")
        return None

def apply_config(config):
    if not config:
        return

    print("Applying SuperCPU Configuration...")
    
    # 1. Clock Speed
    clock_speed = config.get("system", {}).get("clock_speed_mhz", 20)
    print(f"  - Setting Clock Speed: {clock_speed} MHz")
    # TODO: Write to FPGA PLL Register via /dev/mem or sysfs
    # e.g., write_register(REG_PLL_DIV, calculate_div(clock_speed))

    # 2. Memory Configuration
    ram_size = config.get("memory", {}).get("super_ram_size_mb", 16)
    print(f"  - Configuring SuperRAM: {ram_size} MB")
    # TODO: Configure Memory Controller

    # 3. AI Co-Processor
    ai_enabled = config.get("ai_coprocessor", {}).get("enabled", False)
    if ai_enabled:
        print("  - AI Co-Processor: ENABLED")
        # TODO: Start AI Service Daemon
    
    print("Configuration Applied Successfully.")

if __name__ == "__main__":
    # Check for local config first (dev mode), then system config
    config_path = DEFAULT_CONFIG_FILE if os.path.exists(DEFAULT_CONFIG_FILE) else CONFIG_FILE
    
    config = load_config(config_path)
    apply_config(config)
