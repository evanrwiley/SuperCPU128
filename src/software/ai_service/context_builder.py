import json

# Commodore 64 Hardware Register Map
# Used to inject context into AI prompts
HARDWARE_MAP = {
    0xD000: "VIC-II Sprite 0 X",
    0xD001: "VIC-II Sprite 0 Y",
    0xD011: "VIC-II Control Register 1 (Screen Height, RASTER8)",
    0xD012: "VIC-II Raster Line",
    0xD020: "VIC-II Border Color",
    0xD021: "VIC-II Background Color 0",
    0xD400: "SID Voice 1 Freq Low",
    0xD404: "SID Voice 1 Control",
    0xDC00: "CIA1 Data Port A (Keyboard/Joystick)",
    0xDC01: "CIA1 Data Port B (Keyboard/Joystick)",
    0xDD00: "CIA2 Data Port A (VIC Bank Select)",
}

def enrich_disassembly(disassembly_lines):
    """
    Takes raw disassembly and appends hardware context.
    Input: ["LDA $D020", "STA $D021"]
    Output: ["LDA $D020 ; [VIC-II Border Color]", "STA $D021 ; [VIC-II Background Color 0]"]
    """
    enriched = []
    for line in disassembly_lines:
        # Simple heuristic to find hex addresses (e.g., $D020)
        # In a real implementation, use regex or the disassembler's symbol table
        comment = ""
        for addr, name in HARDWARE_MAP.items():
            hex_addr = f"${addr:04X}"
            if hex_addr in line:
                comment = f" ; [{name}]"
                break
        enriched.append(line + comment)
    return enriched

def build_analysis_prompt(code_block, user_intent="explain"):
    """
    Constructs the prompt for the AI Provider.
    """
    enriched_code = enrich_disassembly(code_block)
    code_text = "\n".join(enriched_code)
    
    if user_intent == "explain":
        return (
            "You are an expert Commodore 64/128 assembly programmer.\n"
            "Analyze the following 6502/65816 code.\n"
            "1. Explain what the routine does in high-level terms.\n"
            "2. Add line-by-line comments explaining the logic.\n"
            "3. Identify any potential bugs or optimizations.\n\n"
            "CODE:\n"
            f"{code_text}"
        )
    elif user_intent == "optimize":
        return (
            "You are an expert optimization engine.\n"
            "Rewrite the following 6502 code to be faster (fewer cycles).\n"
            "Maintain exact functionality.\n\n"
            "CODE:\n"
            f"{code_text}"
        )
    
    return code_text
