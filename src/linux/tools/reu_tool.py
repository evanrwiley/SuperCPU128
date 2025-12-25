#!/usr/bin/env python3
import argparse
import sys
import os

# Add services path
sys.path.append(os.path.join(os.path.dirname(__file__), '../services'))

from reu_manager import ReuManager

def main():
    parser = argparse.ArgumentParser(description="SuperCPU REU Image Manager")
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')

    # Load
    load_parser = subparsers.add_parser('load', help='Load an REU image from file')
    load_parser.add_argument('filename', help='Path to the REU image file')

    # Save
    save_parser = subparsers.add_parser('save', help='Save current REU memory to file')
    save_parser.add_argument('filename', help='Path to save the REU image file')

    # Clear
    subparsers.add_parser('clear', help='Clear REU memory (fill with zeros)')

    # Autoload
    auto_parser = subparsers.add_parser('autoload', help='Configure autoload settings')
    auto_parser.add_argument('--enable', action='store_true', help='Enable autoload')
    auto_parser.add_argument('--disable', action='store_true', help='Disable autoload')
    auto_parser.add_argument('--file', help='File to autoload (required if enabling)')

    args = parser.parse_args()
    
    mgr = ReuManager()

    if args.command == 'load':
        if mgr.load_image(args.filename):
            print("Image loaded successfully.")
        else:
            print("Failed to load image.")
            sys.exit(1)

    elif args.command == 'save':
        if mgr.save_image(args.filename):
            print("Image saved successfully.")
        else:
            print("Failed to save image.")
            sys.exit(1)

    elif args.command == 'clear':
        mgr.clear_memory()
        print("REU memory cleared.")

    elif args.command == 'autoload':
        if args.disable:
            mgr.set_autoload("", False)
            print("Autoload disabled.")
        elif args.enable:
            if not args.file:
                print("Error: --file is required when enabling autoload.")
                sys.exit(1)
            mgr.set_autoload(args.file, True)
            print(f"Autoload enabled for {args.file}.")
        else:
            # Show status
            config = mgr.config.get('reu', {})
            print(f"Autoload: {config.get('autoload')}")
            print(f"Image: {config.get('default_image')}")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
