import json
import os
from typing import Dict, Any, List

class RetroArchitect:
    def __init__(self, project_path: str):
        self.project_path = project_path
        self.manifest_file = os.path.join(project_path, 'project.json')
        self.kb_path = os.path.join(os.path.dirname(__file__), '..', 'knowledge_base')
        self.manifest = self._load_manifest()
        self.machine_def = self._load_machine_def()

    def _load_machine_def(self) -> Dict[str, Any]:
        target = self.manifest.get('target_hardware', 'C64').lower()
        def_file = ""
        
        if "supercpu" in target:
            def_file = "scpu_def.json"
        elif "c128" in target:
            def_file = "c128_def.json"
        else:
            def_file = "c64_def.json"
            
        path = os.path.join(self.kb_path, def_file)
        if os.path.exists(path):
            with open(path, 'r') as f:
                return json.load(f)
        return {}

    def _load_manifest(self) -> Dict[str, Any]:
        if not os.path.exists(self.manifest_file):
            return self._create_default_manifest()
        with open(self.manifest_file, 'r') as f:
            return json.load(f)

    def _create_default_manifest(self) -> Dict[str, Any]:
        return {
            "project_name": "Untitled",
            "target_hardware": "C64",
            "memory_map": {
                "basic_start": 2049,  # $0801
                "basic_end": 40960,   # $A000
                "free_bytes": 38911
            },
            "assets": {
                "sprites": 0,
                "levels": 0
            }
        }

    def analyze_request(self, user_request: str) -> str:
        """
        Analyzes a user request against the current project constraints.
        Returns a prompt for the LLM to generate the response.
        """
        # 1. Get current state
        free_mem = self.manifest['memory_map']['free_bytes']
        target = self.manifest['target_hardware']
        
        # 2. Heuristic Analysis (Simple keyword matching for now)
        estimated_cost = 0
        if "level" in user_request.lower():
            estimated_cost = 2048 # Assume 2KB per level
        if "sprite" in user_request.lower():
            estimated_cost = 64   # 64 bytes per sprite
        if "music" in user_request.lower():
            estimated_cost = 4096 # 4KB for a SID tune

        # 3. Load Coding Guidelines
        guidelines = ""
        guide_path = os.path.join(self.kb_path, "coding_guidelines.md")
        if os.path.exists(guide_path):
            with open(guide_path, 'r') as f:
                guidelines = f.read()

        # 4. Construct the Context
        context = (
            f"SYSTEM CONTEXT:\n"
            f"Target Machine: {target}\n"
            f"Machine Definition: {json.dumps(self.machine_def, indent=2)}\n"
            f"Coding Guidelines:\n{guidelines}\n\n"
            f"CURRENT PROJECT STATE:\n"
            f"- Free Memory: {free_mem} bytes ({free_mem/1024:.1f} KB)\n"
            f"- Estimated Cost of Request: {estimated_cost} bytes\n\n"
            f"USER REQUEST: \"{user_request}\"\n\n"
            f"INSTRUCTION: Act as the Retro Architect. "
            f"Use the Machine Definition to ensure your advice is technically accurate for the {target}. "
            f"If the cost ({estimated_cost}) > free memory ({free_mem}), warn the user. "
            f"Otherwise, propose a plan."
        )
        
        return context

    def update_manifest(self, key: str, value: Any):
        self.manifest[key] = value
        with open(self.manifest_file, 'w') as f:
            json.dump(self.manifest, f, indent=2)

# Example Usage
if __name__ == "__main__":
    architect = RetroArchitect(".")
    prompt = architect.analyze_request("I want to add 5 new levels to the game.")
    print(prompt)
