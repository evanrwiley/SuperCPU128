import os
import sys

# Add parent directory to path to import ai_manager
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'ai_service'))
try:
    from ai_manager import AIService
except ImportError:
    pass

class SIDLab:
    def __init__(self, config_path='../ai_service/config.json'):
        self.ai = AIService(config_path)
        self.prompt_path = os.path.join(os.path.dirname(__file__), '..', 'ai_service', 'prompts', 'sid_composer.txt')

    def _load_system_prompt(self):
        if os.path.exists(self.prompt_path):
            with open(self.prompt_path, 'r') as f:
                return f.read()
        return "Generate C64 SID Music."

    def compose_sfx(self, description: str) -> str:
        """
        Generates a sound effect routine in Assembly.
        """
        system_prompt = self._load_system_prompt()
        full_prompt = f"{system_prompt}\n\nUSER REQUEST: Create a sound effect for: {description}"
        
        response = self.ai.generate_completion(full_prompt)
        return response

    def save_sfx(self, asm_code: str, filename: str):
        with open(filename, 'w') as f:
            f.write(asm_code)

# Example Usage
if __name__ == "__main__":
    lab = SIDLab()
    sfx = lab.compose_sfx("Laser blast")
    lab.save_sfx(sfx, "laser.asm")
    print("SFX saved to laser.asm")
