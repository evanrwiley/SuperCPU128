import socket
import time
import select
import sys
import os
import pty
import subprocess
from fpga_interface import FpgaInterface
from config_manager import ConfigManager

class LocalProcessConnection:
    """Wraps a local subprocess (PTY) to look like a socket"""
    def __init__(self, command):
        self.master_fd, self.slave_fd = pty.openpty()
        self.process = subprocess.Popen(
            command,
            stdin=self.slave_fd,
            stdout=self.slave_fd,
            stderr=self.slave_fd,
            shell=True,
            preexec_fn=os.setsid,
            close_fds=True
        )
        os.close(self.slave_fd) # Close slave in parent

    def send(self, data):
        try:
            os.write(self.master_fd, data)
        except OSError:
            pass

    def recv(self, bufsize):
        try:
            return os.read(self.master_fd, bufsize)
        except OSError:
            return b""

    def close(self):
        try:
            os.close(self.master_fd)
            self.process.terminate()
            self.process.wait()
        except:
            pass
        
    def fileno(self):
        return self.master_fd

class ZiModemBridge:
    def __init__(self):
        self.config = ConfigManager()
        self.fpga = FpgaInterface()
        self.connected = False
        self.sock = None
        self.server_sock = None
        self.client_sock = None
        self.buffer = b""
        self.command_mode = True
        self.echo = True
        self.verbose = True
        
        # Load config
        self.listen_port = self.config.get('zimodem', {}).get('port', 6400)
        self.enabled = self.config.get('zimodem', {}).get('enabled', True)
        
        self.is_ringing = False
        
        if self.enabled:
            self.start_server()
        print("[ZiModem] Bridge Service Started")

    def start_server(self):
        try:
            self.server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_sock.bind(('0.0.0.0', self.listen_port))
            self.server_sock.listen(1)
            self.server_sock.setblocking(False)
            print(f"[Network] Listening on port {self.listen_port}")
        except Exception as e:
            print(f"[Network] Server Start Failed: {e}")

    def check_incoming_connection(self):
        if self.server_sock and not self.connected and not self.is_ringing:
            try:
                ready, _, _ = select.select([self.server_sock], [], [], 0)
                if ready:
                    client, addr = self.server_sock.accept()
                    print(f"[Network] Incoming connection from {addr}")
                    self.client_sock = client
                    self.client_sock.setblocking(False)
                    self.is_ringing = True
            except Exception as e:
                print(f"[Network] Accept Error: {e}")

    def send_ring(self):
        if self.is_ringing:
            self.send_to_c64("RING\r\n")

    def answer_call(self):
        if self.is_ringing and self.client_sock:
            self.sock = self.client_sock
            self.connected = True
            self.command_mode = False
            self.is_ringing = False
            self.send_to_c64("CONNECT 57600\r\n")
            print("[Network] Call Answered")
        else:
            self.send_to_c64("NO CARRIER\r\n")

    def send_to_c64(self, data):
        """Writes bytes to the FPGA RX FIFO"""
        if isinstance(data, str):
            data = data.encode('ascii', errors='ignore')
        
        for byte in data:
            # Spin wait or retry if FIFO is full (simple implementation)
            while not self.fpga.write_rx_fifo(byte):
                time.sleep(0.001)

    def process_at_command(self, cmd):
        cmd = cmd.strip().upper()
        print(f"[Command] {cmd}")
        
        if cmd == "AT":
            self.send_to_c64("OK\r\n")
        elif cmd.startswith("ATDT"):
            # Dial: ATDT host:port
            addr = cmd[4:].strip()
            self.connect(addr)
        elif cmd == "ATH":
            self.disconnect()
            self.send_to_c64("OK\r\n")
        elif cmd == "ATA":
            self.answer_call()
        elif cmd == "ATI":
            self.send_to_c64("SuperCPU ZiModem Bridge V1.0\r\nOK\r\n")
        else:
            self.send_to_c64("ERROR\r\n")

    def connect(self, addr_str):
        try:
            # Check for Special Local Connections
            if addr_str.upper() == "SIMH":
                print(f"[Network] Starting Local SIMH PDP-11...")
                self.send_to_c64(f"BOOTING PDP-11...\r\n")
                # Assuming simh is installed and a boot script exists
                # We use a wrapper script to handle the specific simh configuration
                pdp_script = os.path.join(os.path.dirname(__file__), '../../../data/pdp11/run_pdp11.sh')
                if os.path.exists(pdp_script):
                    self.sock = LocalProcessConnection(pdp_script)
                else:
                    # Fallback if script missing
                    self.sock = LocalProcessConnection("pdp11")
                
                self.connected = True
                self.command_mode = False
                return

            if addr_str.upper() == "SHELL":
                print(f"[Network] Starting Local Shell...")
                self.send_to_c64(f"STARTING LINUX SHELL...\r\n")
                self.sock = LocalProcessConnection("/bin/bash -i")
                self.connected = True
                self.command_mode = False
                return

            if ":" in addr_str:
                host, port = addr_str.split(":")
                port = int(port)
            else:
                host = addr_str
                port = 23 # Default Telnet
            
            print(f"[Network] Connecting to {host}:{port}...")
            self.send_to_c64(f"DIALING {host}:{port}...\r\n")
            
            self.sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.sock.settimeout(5)
            self.sock.connect((host, port))
            self.sock.setblocking(False)
            
            self.connected = True
            self.command_mode = False
            self.send_to_c64("CONNECT 57600\r\n")
            print("[Network] Connected")
            
        except Exception as e:
            print(f"[Network] Connection Failed: {e}")
            self.send_to_c64(f"NO CARRIER\r\n")
            self.connected = False

    def disconnect(self):
        if self.sock:
            self.sock.close()
        self.sock = None
        self.connected = False
        self.command_mode = True
        print("[Network] Disconnected")

    def run(self):
        input_buffer = ""
        last_ring_time = 0
        
        try:
            while True:
                # 0. Check for Incoming Calls
                self.check_incoming_connection()
                
                # Ring every 3 seconds if ringing
                if self.is_ringing:
                    if time.time() - last_ring_time > 3:
                        self.send_ring()
                        last_ring_time = time.time()

                # 1. Read from C64 (FPGA TX FIFO)
                byte = self.fpga.read_tx_fifo()
                if byte is not None:
                    char = chr(byte)
                    
                    if self.command_mode:
                        if self.echo:
                            self.send_to_c64(char)
                            
                        if byte == 13: # CR
                            self.send_to_c64("\n") # Add LF
                            self.process_at_command(input_buffer)
                            input_buffer = ""
                        else:
                            input_buffer += char
                    else:
                        # Passthrough mode (send to socket)
                        if self.sock:
                            try:
                                self.sock.send(bytes([byte]))
                            except BrokenPipeError:
                                self.disconnect()
                                self.send_to_c64("\r\nNO CARRIER\r\n")

                        # Check for escape sequence (+++) - Simplified
                        # In a real implementation, we need timing guards
                        if char == '+':
                            if input_buffer == "++":
                                self.command_mode = True
                                self.send_to_c64("\r\nOK\r\n")
                                input_buffer = ""
                            else:
                                input_buffer += "+"
                        else:
                            input_buffer = ""

                # 2. Read from Network (Socket)
                if self.connected and self.sock:
                    try:
                        ready_to_read, _, _ = select.select([self.sock], [], [], 0)
                        if ready_to_read:
                            net_data = self.sock.recv(1024)
                            if not net_data:
                                self.disconnect()
                                self.send_to_c64("\r\nNO CARRIER\r\n")
                            else:
                                self.send_to_c64(net_data)
                    except Exception as e:
                        print(f"Socket Error: {e}")
                        self.disconnect()

                time.sleep(0.0001) # Prevent 100% CPU usage

        except KeyboardInterrupt:
            print("Stopping Bridge...")
            self.fpga.close()

if __name__ == "__main__":
    bridge = ZiModemBridge()
    bridge.run()
