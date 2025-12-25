import os
import subprocess
import tempfile

class BuildManager:
    def __init__(self, project_path="."):
        self.project_path = project_path
        self.assembler_path = "64tass" # Assumes 64tass is in PATH

    def assemble(self, source_file: str, output_file: str = "out.prg") -> dict:
        """
        Runs the assembler on the source file.
        Returns a dict with status, output, and error messages.
        """
        if not os.path.exists(source_file):
            return {"success": False, "message": f"Source file {source_file} not found."}

        # Command: 64tass -C -a -o out.prg --export-labels labels.txt source.asm
        label_file = "labels.txt"
        cmd = [
            self.assembler_path,
            "-C",       # Case sensitive
            "-a",       # ASCII input
            "--export-labels", label_file,
            "-o", output_file,
            source_file
        ]

        try:
            result = subprocess.run(
                cmd, 
                capture_output=True, 
                text=True, 
                cwd=self.project_path
            )
            
            success = (result.returncode == 0)
            parsed_errors = self._parse_errors(result.stderr)
            
            return {
                "success": success,
                "stdout": result.stdout,
                "stderr": result.stderr,
                "errors": parsed_errors,
                "output_file": output_file if success else None,
                "label_file": label_file if success else None
            }

        except FileNotFoundError:
            return {"success": False, "message": "Assembler '64tass' not found. Please install it."}
        except Exception as e:
            return {"success": False, "message": str(e)}

    def _parse_errors(self, stderr: str) -> list:
        """
        Parses 64tass error output into a structured list.
        Example: "test.asm:5: error: ..."
        """
        errors = []
        for line in stderr.splitlines():
            if ": error:" in line or ": warning:" in line:
                parts = line.split(":", 3)
                if len(parts) >= 3:
                    try:
                        errors.append({
                            "file": parts[0].strip(),
                            "line": int(parts[1]),
                            "message": parts[2].strip() + (parts[3] if len(parts)>3 else "")
                        })
                    except ValueError:
                        pass # Skip if line number isn't an int
        return errors

    def inject_binary(self, binary_file: str, memory_address: int = None):
        """
        Injects the compiled binary into the C64 memory via the Shared Memory Bridge.
        (Mock implementation for now - requires /dev/mem access on DE10-Nano)
        """
        if not os.path.exists(binary_file):
            return False
            
        with open(binary_file, "rb") as f:
            data = f.read()
            
        # TODO: Write 'data' to the physical memory address mapped to the C64 bus
        # For the SuperCPU, this is likely a specific range in the HPS-FPGA bridge.
        print(f"Injecting {len(data)} bytes from {binary_file} into C64 memory...")
        return True

# Example Usage
if __name__ == "__main__":
    builder = BuildManager()
    # Create a dummy file for testing
    with open("test.asm", "w") as f:
        f.write("*=$0801\n .byte $00\n")
    
    res = builder.assemble("test.asm")
    print(res)
