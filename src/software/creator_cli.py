import argparse
import sys
import os

# Import tools
from tools.sprite_studio import SpriteStudio
from tools.sid_lab import SIDLab
from tools.build_manager import BuildManager
from tools.debugger_interface import DebuggerInterface
from ai_service.retro_architect import RetroArchitect

def main():
    parser = argparse.ArgumentParser(description='SuperCPU Creator Studio CLI')
    subparsers = parser.add_subparsers(dest='command', help='Sub-command help')

    # Sprite Command
    parser_sprite = subparsers.add_parser('sprite', help='Sprite Studio Tools')
    parser_sprite.add_argument('--generate', type=str, help='Description of sprite to generate')
    parser_sprite.add_argument('--output', type=str, default='sprite.bin', help='Output filename')
    parser_sprite.add_argument('--format', type=str, choices=['bin', 'asm'], default='bin', help='Output format')

    # SID Command
    parser_sid = subparsers.add_parser('sid', help='SID Lab Tools')
    parser_sid.add_argument('--compose', type=str, help='Description of sound to compose')
    parser_sid.add_argument('--output', type=str, default='sound.asm', help='Output filename')

    # Project Command
    parser_proj = subparsers.add_parser('project', help='Project Management')
    parser_proj.add_argument('--analyze', type=str, help='Analyze a user request against project constraints')
    parser_proj.add_argument('--path', type=str, default='.', help='Project path')

    # Build Command
    parser_build = subparsers.add_parser('build', help='Build and Inject Code')
    parser_build.add_argument('--source', type=str, required=True, help='Source file to assemble')
    parser_build.add_argument('--inject', action='store_true', help='Inject binary into C64 memory after build')

    # Debug Command
    parser_debug = subparsers.add_parser('debug', help='Debugger Control')
    parser_debug.add_argument('--halt', action='store_true', help='Halt CPU')
    parser_debug.add_argument('--resume', action='store_true', help='Resume CPU')
    parser_debug.add_argument('--peek', type=str, help='Read address (hex)')

    args = parser.parse_args()

    if args.command == 'sprite':
        if args.generate:
            print(f"Generating sprite: '{args.generate}'...")
            studio = SpriteStudio()
            data = studio.generate_sprite(args.generate)
            studio.save_sprite(data, args.output, args.format)
            print(f"Saved to {args.output}")
        else:
            print("Error: --generate description required")

    elif args.command == 'sid':
        if args.compose:
            print(f"Composing sound: '{args.compose}'...")
            lab = SIDLab()
            asm = lab.compose_sfx(args.compose)
            lab.save_sfx(asm, args.output)
            print(f"Saved to {args.output}")
        else:
            print("Error: --compose description required")

    elif args.command == 'project':
        if args.analyze:
            architect = RetroArchitect(args.path)
            prompt = architect.analyze_request(args.analyze)
            print("--- AI Context Prompt ---")
            print(prompt)
            print("-------------------------")
        else:
            print("Error: --analyze request required")

from tools.symbol_manager import SymbolManager

# ... (inside main)

    elif args.command == 'build':
        builder = BuildManager()
        print(f"Building {args.source}...")
        res = builder.assemble(args.source)
        if res['success']:
            print("Build Successful!")
            if args.inject:
                builder.inject_binary(res['output_file'])
        else:
            print("Build Failed:")
            # Print structured errors for the C64 UI to parse
            import json
            print("--- ERROR JSON START ---")
            print(json.dumps(res['errors']))
            print("--- ERROR JSON END ---")
            print(res['stderr'])

    elif args.command == 'debug':
        dbg = DebuggerInterface()
        sym = SymbolManager("labels.txt") # Load symbols if available
        
        if args.halt:
            dbg.halt_cpu()
        elif args.resume:
            dbg.resume_cpu()
        elif args.peek:
            # Resolve symbol or hex address
            addr = sym.resolve(args.peek)
            if addr is not None:
                val = dbg.read_memory(addr)
                print(f"{args.peek} (${addr:04X}) = ${val:02X}")
            else:
                print(f"Error: Could not resolve '{args.peek}'")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()
