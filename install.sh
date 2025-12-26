#!/bin/bash

# SuperCPU Installer Script
# Runs on the DE10-Nano (ARM Linux)

echo "========================================"
echo "   SuperCPU Creator Studio Installer    "
echo "========================================"


# Install System Tools (SIMH, socat, git, 64tass assembler)
if command -v apt-get &> /dev/null; then
    echo "Installing System Tools..."
    sudo apt-get update
    sudo apt-get install -y simh socat git 64tass python3-venv
fi

# 1. Install Python Dependencies (using venv to avoid system conflicts)
echo "[1/4] Setting up Python Environment..."
VENV_DIR="venv"
if [ ! -d "$VENV_DIR" ]; then
    python3 -m venv "$VENV_DIR"
    echo "Created virtual environment in $VENV_DIR"
fi

# Activate venv and install
source "$VENV_DIR/bin/activate"
pip3 install --upgrade pip
pip3 install requests pyserial google-generativeai google-ai-generativelanguage

# Install Ollama (AI Service)
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama AI Service..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "Ollama is already installed."
fi

# 4. Setup PDP-11 Environment (PiDP-11 Style Structure)
echo "[4/4] Configuring Mainframe Environment..."
PDP_ROOT="data/pdp11"
mkdir -p "$PDP_ROOT/systems/rsts"
mkdir -p "$PDP_ROOT/systems/unix7"
mkdir -p "$PDP_ROOT/systems/rt11"
mkdir -p "$PDP_ROOT/bootscripts"

# Create a sample boot.ini for RSTS if it doesn't exist
if [ ! -f "$PDP_ROOT/systems/rsts/boot.ini" ]; then
    cat <<EOF > "$PDP_ROOT/systems/rsts/boot.ini"
; Sample RSTS/E Boot Configuration
set cpu 11/70
set cpu 2M
; Uncomment below when you have a disk image
; set rq0 ra81
; att rq0 rsts_v7.dsk
; boot rq0
EOF
fi

# 2. Compile Bridge Daemon
echo "[2/4] Compiling Bridge Daemon..."
cd src/software/bridge_daemon
if gcc daemon.c -o bridge_daemon; then
    echo "Daemon compiled successfully."
else
    echo "Error: Compilation failed."
    exit 1
fi
cd ../../..

# 3. Setup System Service
echo "[3/4] Setting up System Service..."
SERVICE_FILE="/etc/systemd/system/supercpu-bridge.service"

# Create service file content
cat <<EOF > supercpu-bridge.service
[Unit]
Description=SuperCPU Bridge Daemon
After=network.target ollama.service

[Service]
ExecStart=$(pwd)/venv/bin/python3 $(pwd)/src/linux/main.py
WorkingDirectory=$(pwd)
Environment="PATH=$(pwd)/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# Install service (requires sudo)
if [ "$EUID" -eq 0 ]; then
    mv supercpu-bridge.service $SERVICE_FILE
    systemctl daemon-reload
    systemctl enable supercpu-bridge
    systemctl start supercpu-bridge
    echo "Service installed and started."
else
    echo "Warning: Not running as root. Service file created but not installed."
    echo "Run: sudo mv supercpu-bridge.service $SERVICE_FILE"
fi

echo "Installation Complete!"
echo "To start the bridge manually: sudo systemctl start supercpu-bridge"
echo "Note: To use Google AI features, ensure you have a GOOGLE_API_KEY environment variable set."

# 4. Build C64 Tools (Requires 64tass)
echo "[4/4] Building C64 UI..."
if command -v 64tass &> /dev/null; then
    mkdir -p bin
    64tass -C -a -o bin/ide_main.prg src/software/c64_ui/ide_main.asm
    echo "C64 UI built to bin/ide_main.prg"
else
    echo "Warning: 64tass not found. Skipping C64 UI build."
fi

echo "========================================"
echo "   Installation Complete!               "
echo "========================================"
