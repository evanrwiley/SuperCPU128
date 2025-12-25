#!/usr/bin/env python3
import curses
import time
import os
import sys
import datetime

# Add services path
sys.path.append(os.path.join(os.path.dirname(__file__), 'services'))
from reu_manager import ReuManager
from diagnostics_manager import DiagnosticsManager

# Mock FPGA Interface (Replace with actual mmap/devmem)
class FPGA:
    def read(self, addr):
        return 0x00
    
    def write(self, addr, data):
        pass

fpga = FPGA()

def draw_menu(stdscr, selected_row_idx, menu_items):
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    
    # Title
    title = "SuperCPU Control Center"
    stdscr.addstr(0, w//2 - len(title)//2, title, curses.A_BOLD)
    
    # Menu Items
    for idx, row in enumerate(menu_items):
        x = w//2 - len(row)//2
        y = h//2 - len(menu_items)//2 + idx
        if idx == selected_row_idx:
            stdscr.attron(curses.color_pair(1))
            stdscr.addstr(y, x, row)
            stdscr.attroff(curses.color_pair(1))
        else:
            stdscr.addstr(y, x, row)
            
    stdscr.refresh()

def bus_sampler_view(stdscr):
    stdscr.clear()
    stdscr.addstr(0, 0, "Bus Sampler / Logic Analyzer")
    stdscr.addstr(2, 0, "Press 't' to Trigger, 'q' to Back")
    
    # Mock Data
    data = [
        "0000: A=E000 D=4C RW=R PHI2=1",
        "0001: A=E001 D=F5 RW=R PHI2=1",
        "0002: A=E002 D=AA RW=R PHI2=1",
    ]
    
    for i, line in enumerate(data):
        stdscr.addstr(4+i, 2, line)
        
    stdscr.refresh()
    while True:
        key = stdscr.getch()
        if key == ord('q'):
            break

def reu_manager_view(stdscr):
    mgr = ReuManager()
    reu_dir = os.path.expanduser("~/reu_images")
    if not os.path.exists(reu_dir):
        os.makedirs(reu_dir)

    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, "REU Manager", curses.A_BOLD)
        
        # Status
        config = mgr.config.get('reu', {})
        stdscr.addstr(2, 0, f"Size: {config.get('size_mb')} MB")
        stdscr.addstr(3, 0, f"Autoload: {'Enabled' if config.get('autoload') else 'Disabled'}")
        stdscr.addstr(4, 0, f"Default Image: {config.get('default_image')}")
        
        stdscr.addstr(6, 0, "Actions:")
        stdscr.addstr(7, 2, "1. Load Image")
        stdscr.addstr(8, 2, "2. Save Image (New)")
        stdscr.addstr(9, 2, "3. Clear Memory")
        stdscr.addstr(10, 2, "4. Toggle Autoload (Current Default)")
        stdscr.addstr(11, 2, "5. Set Default Image")
        stdscr.addstr(13, 0, "Press 'q' to Back")
        
        stdscr.refresh()
        key = stdscr.getch()
        
        if key == ord('q'):
            break
        elif key == ord('1'): # Load
            files = [f for f in os.listdir(reu_dir) if f.endswith('.reu')]
            if not files:
                stdscr.addstr(15, 0, "No .reu files found in ~/reu_images")
                stdscr.refresh()
                time.sleep(2)
                continue
                
            # Simple file selection (first one for now, or list)
            # TODO: Implement proper file selector
            selected_file = files[0] 
            stdscr.addstr(15, 0, f"Loading {selected_file}...")
            stdscr.refresh()
            mgr.load_image(os.path.join(reu_dir, selected_file))
            stdscr.addstr(16, 0, "Done.")
            time.sleep(1)
            
        elif key == ord('2'): # Save
            filename = f"reu_{int(time.time())}.reu"
            path = os.path.join(reu_dir, filename)
            stdscr.addstr(15, 0, f"Saving to {filename}...")
            stdscr.refresh()
            mgr.save_image(path)
            stdscr.addstr(16, 0, "Done.")
            time.sleep(1)
            
        elif key == ord('3'): # Clear
            stdscr.addstr(15, 0, "Clearing memory...")
            stdscr.refresh()
            mgr.clear_memory()
            stdscr.addstr(16, 0, "Done.")
            time.sleep(1)
            
        elif key == ord('4'): # Toggle Autoload
            current = config.get('autoload')
            mgr.set_autoload(config.get('default_image'), not current)
            
        elif key == ord('5'): # Set Default
            files = [f for f in os.listdir(reu_dir) if f.endswith('.reu')]
            if files:
                # Just pick the first one for this simple demo
                path = os.path.join(reu_dir, files[0])
                mgr.set_autoload(path, True)
                stdscr.addstr(15, 0, f"Set default to {files[0]}")
                time.sleep(1)

def diagnostics_view(stdscr):
    mgr = DiagnosticsManager()
    
    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, "System Diagnostics", curses.A_BOLD)
        stdscr.addstr(2, 0, "Select a Diagnostic ROM to load:")
        
        roms = mgr.list_diagnostics()
        if not roms:
            stdscr.addstr(4, 2, "No diagnostic ROMs found.")
            stdscr.addstr(6, 0, "Press 'q' to Back")
        else:
            # Limit list to fit screen
            max_display = 10
            for i, rom in enumerate(roms[:max_display]):
                stdscr.addstr(4+i, 2, f"{i+1}. {rom}")
            
            stdscr.addstr(6+len(roms[:max_display]), 0, "Press number to load, 'q' to Back")

        stdscr.refresh()
        key = stdscr.getch()
        
        if key == ord('q'):
            break
        elif key >= ord('1') and key < ord('1') + len(roms[:max_display]):
            idx = key - ord('1')
            selected_rom = roms[idx]
            
            stdscr.clear()
            stdscr.addstr(0, 0, f"Loading {selected_rom}...", curses.A_BOLD)
            stdscr.addstr(2, 0, "Select Mode:")
            stdscr.addstr(4, 2, "1. C64 Mode")
            stdscr.addstr(5, 2, "2. C128 Mode")
            stdscr.refresh()
            
            mode_key = stdscr.getch()
            mode = "C64"
            if mode_key == ord('2'):
                mode = "C128"
                
            stdscr.addstr(7, 0, f"Flashing FPGA for {mode}...")
            stdscr.refresh()
            
            if mgr.run_diagnostic(selected_rom, mode):
                stdscr.addstr(9, 0, "Success! System is resetting into Diagnostic Mode.")
            else:
                stdscr.addstr(9, 0, "Error: Failed to load diagnostic.")
                
            time.sleep(2)

def diagnostics_view(stdscr):
    mgr = DiagnosticsManager()
    
    while True:
        stdscr.clear()
        stdscr.addstr(0, 0, "System Diagnostics", curses.A_BOLD)
        stdscr.addstr(2, 0, "Select a Diagnostic ROM to load:")
        
        roms = mgr.list_diagnostics()
        if not roms:
            stdscr.addstr(4, 2, "No diagnostic ROMs found.")
            stdscr.addstr(6, 0, "Press 'q' to Back")
        else:
            # Limit list to fit screen
            max_display = 10
            for i, rom in enumerate(roms[:max_display]):
                # Display Title and System
                title = rom.get('title', rom['filename'])
                system = rom.get('system', 'Unknown')
                stdscr.addstr(4+i, 2, f"{i+1}. [{system}] {title}")
            
            stdscr.addstr(6+len(roms[:max_display]), 0, "Press number to load, 'q' to Back")
            
            # Show description for selected item (mock selection for now, or just hint)
            stdscr.addstr(8+len(roms[:max_display]), 0, "Description:", curses.A_UNDERLINE)
            stdscr.addstr(9+len(roms[:max_display]), 0, "Select a test to see details")

        stdscr.refresh()
        key = stdscr.getch()
        
        if key == ord('q'):
            break
        elif key >= ord('1') and key < ord('1') + len(roms[:max_display]):
            idx = key - ord('1')
            selected_rom = roms[idx]
            
            stdscr.clear()
            stdscr.addstr(0, 0, f"Loading {selected_rom['title']}...", curses.A_BOLD)
            stdscr.addstr(2, 0, f"Description: {selected_rom.get('description', '')}")
            stdscr.addstr(4, 0, "Select Mode:")
            stdscr.addstr(6, 2, "1. C64 Mode")
            stdscr.addstr(7, 2, "2. C128 Mode")
            stdscr.refresh()
            
            mode_key = stdscr.getch()
            mode = "C64"
            if mode_key == ord('2'):
                mode = "C128"
                
            stdscr.addstr(9, 0, f"Flashing FPGA for {mode}...")
            stdscr.refresh()
            
            # Pass filename to run_diagnostic
            if mgr.run_diagnostic(selected_rom['filename'], mode):
                stdscr.addstr(11, 0, "Success! System is resetting into Diagnostic Mode.")
            else:
                stdscr.addstr(11, 0, "Error: Failed to load diagnostic.")
                
            time.sleep(2)

def main(stdscr):
    curses.curs_set(0)
    curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)
    
    menu_items = [
        "System Status",
        "Video Configuration",
        "Audio Configuration",
        "DMA Transfer Test",
        "Bus Sampler",
        "REU Manager",
        "System Diagnostics",
        "Exit"
    ]
    
    current_row = 0
    
    while True:
        draw_menu(stdscr, current_row, menu_items)
        key = stdscr.getch()
        
        if key == curses.KEY_UP and current_row > 0:
            current_row -= 1
        elif key == curses.KEY_DOWN and current_row < len(menu_items) - 1:
            current_row += 1
        elif key == curses.KEY_ENTER or key in [10, 13]:
            if menu_items[current_row] == "Exit":
                break
            elif menu_items[current_row] == "Bus Sampler":
                bus_sampler_view(stdscr)
            elif menu_items[current_row] == "REU Manager":
                reu_manager_view(stdscr)
            elif menu_items[current_row] == "System Diagnostics":
                diagnostics_view(stdscr)
            else:
                stdscr.addstr(0, 0, f"Selected: {menu_items[current_row]}")
                stdscr.refresh()
                time.sleep(1)

if __name__ == "__main__":
    curses.wrapper(main)
