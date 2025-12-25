import re
import os

class SymbolManager:
    def __init__(self, label_file_path: str):
        self.label_file_path = label_file_path
        self.address_to_symbol = {}
        self.symbol_to_address = {}
        self.load_symbols()

    def load_symbols(self):
        """
        Parses a 64tass label file.
        Format usually: "label = $1234" or "label .eq $1234"
        """
        if not os.path.exists(self.label_file_path):
            return

        self.address_to_symbol = {}
        self.symbol_to_address = {}

        with open(self.label_file_path, 'r') as f:
            for line in f:
                # Regex to capture "Label = $Address" or similar
                # 64tass export format varies, assuming standard: "label = $xxxx"
                match = re.match(r'^\s*(\w+)\s*=\s*\$([0-9a-fA-F]+)', line)
                if match:
                    symbol = match.group(1)
                    addr_str = match.group(2)
                    address = int(addr_str, 16)
                    
                    self.symbol_to_address[symbol] = address
                    self.address_to_symbol[address] = symbol

    def get_symbol(self, address: int) -> str:
        return self.address_to_symbol.get(address, f"${address:04X}")

    def get_address(self, symbol: str) -> int:
        return self.symbol_to_address.get(symbol, None)

    def resolve(self, input_str: str) -> int:
        """
        Resolves a string to an address. 
        Input can be "$D020", "0xD020", "1234", or "BorderColor".
        """
        input_str = input_str.strip()
        
        # Hex
        if input_str.startswith("$"):
            return int(input_str[1:], 16)
        if input_str.lower().startswith("0x"):
            return int(input_str, 16)
            
        # Decimal (if purely digits)
        if input_str.isdigit():
            return int(input_str)
            
        # Symbol
        return self.get_address(input_str)

# Example Usage
if __name__ == "__main__":
    # Create dummy label file
    with open("labels.txt", "w") as f:
        f.write("BorderColor = $D020\n")
        f.write("PlayerX = $C000\n")
        
    sym = SymbolManager("labels.txt")
    print(f"BorderColor is at {hex(sym.resolve('BorderColor'))}")
    print(f"$C000 is {sym.get_symbol(0xC000)}")
