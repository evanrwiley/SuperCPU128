#!/bin/bash

# SuperCPU Installer Script
# Runs on the DE10-Nano (ARM Linux)

echo "========================================"
echo "   SuperCPU Creator Studio Installer    "
echo "========================================"

# 1. Install Dependencies
echo "[1/4] Installing Python Dependencies..."
if command -v pip3 &> /dev/null; then
    pip3 install requests pyserial
else
    echo "Error: pip3 not found. Please install python3-pip."
    exit 1
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
After=network.target

[Service]
ExecStart=$(pwd)/src/software/bridge_daemon/bridge_daemon
WorkingDirectory=$(pwd)/src/software/bridge_daemon
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

# 4. Build C64 Tools (Requires 64tass)
echo "[4/4] Building C64 UI..."
if command -v 64tass &> /dev/null; then
    64tass -C -a -o bin/ide_main.prg src/software/c64_ui/ide_main.asm
    echo "C64 UI built to bin/ide_main.prg"
else
    echo "Warning: 64tass not found. Skipping C64 UI build."
    echo "Please install 64tass to build the C64 client."
fi

echo "========================================"
echo "   Installation Complete!               "
echo "========================================"
