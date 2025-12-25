import time
import threading
import signal
import sys
import os

# Add paths
sys.path.append(os.path.join(os.path.dirname(__file__), 'services'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'tools'))

from robust_watchdog import Watchdog
from zimodem_bridge import ZiModemBridge
from reu_manager import ReuManager

class SuperCPUService:
    def __init__(self):
        self.running = True
        self.watchdog = Watchdog()
        self.bridge = ZiModemBridge()
        self.reu_manager = ReuManager()
        
        # Threads
        self.watchdog_thread = threading.Thread(target=self.run_watchdog)
        self.bridge_thread = threading.Thread(target=self.run_bridge)

    def run_watchdog(self):
        print("[Main] Starting Watchdog...")
        try:
            self.watchdog.run()
        except Exception as e:
            print(f"[Main] Watchdog crashed: {e}")

    def run_bridge(self):
        print("[Main] Starting ZiModem Bridge...")
        try:
            self.bridge.run()
        except Exception as e:
            print(f"[Main] Bridge crashed: {e}")

    def start(self):
        # Check REU Autoload before starting other services
        print("[Main] Checking REU Autoload...")
        self.reu_manager.check_autoload()

        self.watchdog_thread.daemon = True
        self.bridge_thread.daemon = True
        
        self.watchdog_thread.start()
        self.bridge_thread.start()
        
        print("[Main] All services started. Press Ctrl+C to exit.")
        
        try:
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()

    def stop(self):
        print("\n[Main] Stopping services...")
        self.running = False
        # In a real app, we'd signal threads to stop gracefully
        # For now, daemon threads will be killed on exit
        sys.exit(0)

if __name__ == "__main__":
    service = SuperCPUService()
    service.start()
