import threading
import logging
import requests
import json
from library_db import LibraryDatabase

# Placeholder for AI Service URL (e.g., Ollama running locally or external API)
AI_API_URL = "http://localhost:11434/api/generate"
AI_MODEL = "llama3" # or mistral, gemma, etc.

class AiEnricher:
    def __init__(self, db: LibraryDatabase):
        self.db = db
        self.logger = logging.getLogger("AiEnricher")
        self.queue = []
        self.running = False

    def enrich_item_async(self, item_id, basic_metadata):
        """Add item to queue for background processing"""
        self.queue.append((item_id, basic_metadata))
        if not self.running:
            threading.Thread(target=self._process_queue).start()

    def _process_queue(self):
        self.running = True
        while self.queue:
            item_id, metadata = self.queue.pop(0)
            try:
                self._enrich_item(item_id, metadata)
            except Exception as e:
                self.logger.error(f"Error enriching item {item_id}: {e}")
        self.running = False

    def _enrich_item(self, item_id, metadata):
        self.logger.info(f"Enriching item {item_id}: {metadata.get('title')}")
        
        # Construct Prompt
        prompt = f"""
You are an expert retro gaming historian.
Generate a concise description and metadata for this Commodore 64/128 software.

Title: {metadata.get('title')}
Year: {metadata.get('year', 'Unknown')}
Publisher: {metadata.get('publisher', 'Unknown')}

Output ONLY a JSON object with these keys:
- summary: A 2-3 sentence description.
- genre: The specific genre (e.g. Platformer, Shoot 'em up).
- tags: An array of 3-5 keywords.
- description: A longer historical overview (optional).
"""
        
        # Call AI API
        try:
            payload = {
                "model": AI_MODEL,
                "prompt": prompt,
                "stream": False,
                "format": "json" 
            }
            response = requests.post(AI_API_URL, json=payload, timeout=30)
            if response.status_code == 200:
                result = response.json()
                # Parse the 'response' field which contains the actual text/json from LLM
                ai_content = json.loads(result.get('response', '{}'))
                
                # Update DB
                self.db.update_ai_metadata(item_id, ai_content)
                self.logger.info(f"Enrichment complete for {item_id}")
            else:
                self.logger.error(f"AI API Error: {response.status_code}")
                
        except Exception as e:
            self.logger.error(f"AI Request Failed: {e}")

