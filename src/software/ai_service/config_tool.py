import json
import argparse
import os
import sys

CONFIG_FILE = 'config.json'

def load_config():
    if not os.path.exists(CONFIG_FILE):
        print(f"Error: {CONFIG_FILE} not found.")
        sys.exit(1)
    with open(CONFIG_FILE, 'r') as f:
        return json.load(f)

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)
    print("Configuration saved.")

def list_config(config):
    print(f"Active Provider: {config['system']['active_provider']}")
    print("-" * 40)
    for name, data in config['providers'].items():
        status = "[x]" if data['enabled'] else "[ ]"
        print(f"{status} {name.upper()}")
        print(f"    Model: {data['default_model']}")
        print(f"    URL:   {data['base_url']}")
        if data.get('api_key'):
            masked = data['api_key'][:4] + "..." + data['api_key'][-4:] if len(data['api_key']) > 8 else "****"
            print(f"    Key:   {masked}")
        else:
            print(f"    Key:   (none)")
    print("-" * 40)

def update_provider(config, provider, key=None, model=None, url=None, enable=None):
    if provider not in config['providers']:
        print(f"Error: Provider '{provider}' not found.")
        return

    p = config['providers'][provider]
    
    if key is not None:
        p['api_key'] = key
        print(f"Updated API Key for {provider}")
        
    if model is not None:
        p['default_model'] = model
        print(f"Updated Default Model for {provider} to {model}")

    if url is not None:
        p['base_url'] = url
        print(f"Updated URL for {provider}")

    if enable is not None:
        p['enabled'] = (enable.lower() == 'true')
        print(f"Set {provider} enabled to {p['enabled']}")

    save_config(config)

def set_active(config, provider):
    if provider not in config['providers']:
        print(f"Error: Provider '{provider}' not found.")
        return
    
    if not config['providers'][provider]['enabled']:
        print(f"Warning: Provider '{provider}' is currently disabled.")

    config['system']['active_provider'] = provider
    print(f"Active provider set to {provider}")
    save_config(config)

def main():
    parser = argparse.ArgumentParser(description='AI Service Configuration Tool')
    parser.add_argument('--list', action='store_true', help='List current configuration')
    parser.add_argument('--provider', type=str, help='Target provider to configure')
    parser.add_argument('--set-key', type=str, help='Set API Key')
    parser.add_argument('--set-model', type=str, help='Set Default Model')
    parser.add_argument('--set-url', type=str, help='Set Base URL')
    parser.add_argument('--enable', type=str, choices=['true', 'false'], help='Enable/Disable provider')
    parser.add_argument('--set-active', type=str, help='Set the active provider')
    
    args = parser.parse_args()
    config = load_config()

    if args.list:
        list_config(config)
    elif args.set_active:
        set_active(config, args.set_active)
    elif args.provider:
        update_provider(config, args.provider, args.set_key, args.set_model, args.set_url, args.enable)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
