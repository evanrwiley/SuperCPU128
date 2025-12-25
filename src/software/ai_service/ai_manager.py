import json
import os
import sys
import requests
import argparse
from typing import Dict, Any, Optional

# Configuration Paths
CONFIG_FILE = 'config.json'

class AIService:
    def __init__(self, config_path: str):
        self.config = self.load_config(config_path)
        self.active_provider = self.config['system']['active_provider']
        
    def load_config(self, path: str) -> Dict[str, Any]:
        if not os.path.exists(path):
            raise FileNotFoundError(f"Config file not found at {path}")
        with open(path, 'r') as f:
            return json.load(f)

    def get_provider_config(self, provider_name: Optional[str] = None) -> Dict[str, Any]:
        name = provider_name or self.active_provider
        if name not in self.config['providers']:
            raise ValueError(f"Provider '{name}' not configured")
        return self.config['providers'][name]

    def get_available_models(self, provider: Optional[str] = None) -> list:
        provider_name = provider or self.active_provider
        provider_config = self.get_provider_config(provider_name)
        
        if not provider_config['enabled']:
            return [f"Error: Provider '{provider_name}' is disabled."]

        api_key = provider_config.get('api_key', '')
        base_url = provider_config['base_url']

        try:
            if provider_name == 'ollama':
                return self._fetch_ollama_models(base_url)
            elif provider_name == 'openai':
                return self._fetch_openai_models(base_url, api_key)
            elif provider_name == 'google':
                return self._fetch_google_models(base_url, api_key)
            elif provider_name == 'copilot':
                return ["copilot-chat"] # Copilot API doesn't easily list models via standard endpoints
            else:
                return [f"Error: Unknown provider '{provider_name}'"]
        except Exception as e:
            return [f"Error fetching models: {str(e)}"]

    def _fetch_ollama_models(self, base_url: str) -> list:
        url = f"{base_url}/api/tags"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        return [model['name'] for model in data.get('models', [])]

    def _fetch_openai_models(self, base_url: str, api_key: str) -> list:
        url = f"{base_url}/models"
        headers = {"Authorization": f"Bearer {api_key}"}
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        data = response.json()
        return [model['id'] for model in data.get('data', [])]

    def _fetch_google_models(self, base_url: str, api_key: str) -> list:
        # base_url is usually .../v1beta/models
        # We need to GET that URL directly
        url = f"{base_url}?key={api_key}"
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        # Filter for 'generateContent' supported models
        models = []
        for m in data.get('models', []):
            if 'generateContent' in m.get('supportedGenerationMethods', []):
                models.append(m['name'].split('/')[-1]) # remove 'models/' prefix
        return models

    def generate_completion(self, prompt: str, provider: Optional[str] = None, model: Optional[str] = None) -> str:
        provider_name = provider or self.active_provider
        provider_config = self.get_provider_config(provider_name)
        
        if not provider_config['enabled']:
            return f"Error: Provider '{provider_name}' is disabled."

        model_name = model or provider_config['default_model']
        api_key = provider_config.get('api_key', '')
        base_url = provider_config['base_url']
        
        try:
            if provider_name == 'ollama':
                return self._call_ollama(base_url, model_name, prompt)
            elif provider_name == 'openai':
                return self._call_openai(base_url, api_key, model_name, prompt)
            elif provider_name == 'google':
                return self._call_google(base_url, api_key, model_name, prompt)
            elif provider_name == 'copilot':
                return self._call_openai(base_url, api_key, model_name, prompt) # Copilot often uses OpenAI-like schema
            else:
                return f"Error: Unknown provider '{provider_name}'"
        except Exception as e:
            return f"Error calling AI API: {str(e)}"

    def _call_ollama(self, base_url: str, model: str, prompt: str) -> str:
        url = f"{base_url}/api/generate"
        payload = {
            "model": model,
            "prompt": prompt,
            "stream": False
        }
        response = requests.post(url, json=payload)
        response.raise_for_status()
        return response.json().get('response', '')

    def _call_openai(self, base_url: str, api_key: str, model: str, prompt: str) -> str:
        url = f"{base_url}/chat/completions"
        headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": model,
            "messages": [{"role": "user", "content": prompt}],
            "temperature": self.config['system'].get('temperature', 0.7)
        }
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        return response.json()['choices'][0]['message']['content']

    def _call_google(self, base_url: str, api_key: str, model: str, prompt: str) -> str:
        # Google AI Studio / Gemini API
        url = f"{base_url}/{model}:generateContent?key={api_key}"
        headers = {"Content-Type": "application/json"}
        payload = {
            "contents": [{
                "parts": [{"text": prompt}]
            }]
        }
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()
        result = response.json()
        try:
            return result['candidates'][0]['content']['parts'][0]['text']
        except (KeyError, IndexError):
            return f"Error parsing Google response: {result}"

def main():
    parser = argparse.ArgumentParser(description='SuperCPU AI Service Manager')
    parser.add_argument('--prompt', type=str, help='Text prompt for the AI')
    parser.add_argument('--provider', type=str, help='Override active provider')
    parser.add_argument('--model', type=str, help='Override default model')
    parser.add_argument('--list-models', action='store_true', help='Fetch available models from provider')
    parser.add_argument('--config', type=str, default='config.json', help='Path to config file')
    
    args = parser.parse_args()
    
    service = AIService(args.config)

    if args.list_models:
        models = service.get_available_models(args.provider)
        print("Available Models:")
        for m in models:
            print(f"- {m}")
        return
    
    if not args.prompt:
        print("Usage: python ai_manager.py --prompt 'Your question here'")
        return

    response = service.generate_completion(args.prompt, args.provider, args.model)
    print(response)

if __name__ == "__main__":
    main()
