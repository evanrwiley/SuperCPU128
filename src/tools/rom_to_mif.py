import sys
import os

def convert_bin_to_mif(bin_path, mif_path, width=8, depth=None):
    try:
        with open(bin_path, 'rb') as f:
            data = f.read()
    except FileNotFoundError:
        print(f"Error: File {bin_path} not found.")
        return

    size = len(data)
    if depth is None:
        # Round up to next power of 2
        depth = 1
        while depth < size:
            depth *= 2
    
    print(f"Converting {bin_path} ({size} bytes) to {mif_path} (Depth: {depth})")

    with open(mif_path, 'w') as f:
        f.write(f"WIDTH={width};\n")
        f.write(f"DEPTH={depth};\n")
        f.write("ADDRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=HEX;\n")
        f.write("CONTENT BEGIN\n")
        
        for i in range(depth):
            if i < size:
                val = data[i]
            else:
                val = 0 # Padding
            
            f.write(f"\t{i:X} : {val:02X};\n")
            
        f.write("END;\n")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python rom_to_mif.py <input.bin> <output.mif> [depth]")
    else:
        depth = int(sys.argv[3]) if len(sys.argv) > 3 else None
        convert_bin_to_mif(sys.argv[1], sys.argv[2], 8, depth)
