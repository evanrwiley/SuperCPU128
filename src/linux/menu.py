#!/usr/bin/env python3
import curses
import time
import os
import sys

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

def main(stdscr):
    curses.curs_set(0)
    curses.init_pair(1, curses.COLOR_BLACK, curses.COLOR_WHITE)
    
    menu_items = [
        "System Status",
        "Video Configuration",
        "Audio Configuration",
        "DMA Transfer Test",
        "Bus Sampler",
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
            if current_row == 5: # Exit
                break
            elif current_row == 4: # Bus Sampler
                bus_sampler_view(stdscr)
            else:
                stdscr.addstr(0, 0, f"Selected: {menu_items[current_row]}")
                stdscr.refresh()
                time.sleep(1)

if __name__ == "__main__":
    curses.wrapper(main)
