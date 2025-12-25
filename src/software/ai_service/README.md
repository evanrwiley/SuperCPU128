# SuperCPU AI Service

This service runs on the ARM Co-Processor (Linux) of the DE10-Nano and handles communication with various AI providers.

## Features
- **Multi-Provider Support**: Ollama (Local), OpenAI, Google AI Studio (Gemini), GitHub Copilot.
- **Configuration**: JSON-based configuration for API keys and model selection.
- **Extensible**: Easy to add new providers in `ai_manager.py`.

## Installation

1.  **Prerequisites**:
    -   Python 3.x
    -   `pip install requests`

2.  **Setup**:
    -   Edit `config.json` to add your API keys.
    -   Set `"enabled": true` for the providers you want to use.
    -   Choose your `active_provider`.

## Usage

### Command Line
```bash
# Generate text
python ai_manager.py --prompt "Write a 6502 assembly routine to clear the screen"

# List available models from the active provider
python ai_manager.py --list-models

# List models from a specific provider
python ai_manager.py --provider google --list-models
```

### Configuration Tool
You can manage providers and keys using the command-line tool:
```bash
# List current config
python config_tool.py --list

# Set OpenAI Key
python config_tool.py --provider openai --set-key "sk-..." --enable true

# Switch to Google Gemini
python config_tool.py --set-active google
```

### Integration with SuperCPU
The C64/C128 can trigger this service via the Shared Memory Bridge.
1.  C64 writes request to Shared RAM.
2.  ARM Daemon (C program) reads request.
3.  ARM Daemon calls `ai_manager.py` (or imports it).
4.  Result is written back to Shared RAM.

### C64 User Interface
A native C64 configuration utility allows users to manage these settings directly from the Commodore screen.
-   **Location**: `src/software/c64_ui/`
-   **Mechanism**: The C64 app writes commands to the Shared Memory Bridge, which triggers `config_tool.py` on the ARM side.
-   **Features**: Select provider, enter API keys (via keyboard), toggle models.

## Providers

### Ollama (Local)
-   **URL**: `http://localhost:11434` (Default)
-   **Models**: `llama3`, `mistral`, `codellama`
-   **Note**: Runs locally on the FPGA (if powerful enough) or on a networked PC.

### Google AI Studio
-   **Key**: Get from [Google AI Studio](https://aistudio.google.com/apps)
-   **Models**: `gemini-pro`, `gemini-1.5-pro`

### OpenAI / Copilot
-   **Key**: Standard OpenAI key or Copilot Token.
-   **Models**: `gpt-4`, `gpt-3.5-turbo`
