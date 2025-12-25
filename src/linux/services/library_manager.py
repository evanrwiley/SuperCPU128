import os
import logging
import json
from library_db import LibraryDatabase
from ai_enricher import AiEnricher
from fpga_interface import FpgaInterface

class LibraryManager:
    def __init__(self):
        self.db = LibraryDatabase()
        self.ai = AiEnricher(self.db)
        self.fpga = FpgaInterface()
        self.logger = logging.getLogger("LibraryManager")

    def export_library_to_json(self, json_path):
        """Export entire library metadata to a JSON file"""
        try:
            items = self.db.search() # Get all items
            # Fetch full details for each
            full_items = []
            for item in items:
                full_details = self.db.get_item(item['id'])
                # Convert row to dict if needed (already dict from get_item)
                full_items.append(full_details)
            
            with open(json_path, 'w') as f:
                json.dump(full_items, f, indent=4, default=str)
            
            self.logger.info(f"Exported {len(full_items)} items to {json_path}")
            return True
        except Exception as e:
            self.logger.error(f"Export failed: {e}")
            return False

    def import_library_from_json(self, json_path):
        """Import library metadata from a JSON file"""
        try:
            with open(json_path, 'r') as f:
                items = json.load(f)
            
            count = 0
            for item in items:
                # Check if file exists
                # If importing from another system, file paths might be wrong.
                # For now, assume paths are relative or fixed up manually.
                # Or just insert metadata and hope file is there.
                
                # We use add_item but bypass file writing if we just want to update DB
                # But add_item expects file_data.
                # We might need a direct DB insert method for restore.
                # For now, let's just log.
                self.logger.info(f"Importing {item.get('title')}...")
                count += 1
                
            self.logger.info(f"Imported {count} items (Mock implementation)")
            return True
        except Exception as e:
            self.logger.error(f"Import failed: {e}")
            return False

    def ingest_from_ram(self, start_addr=0x0801, end_addr=None, metadata=None):
        """
        Capture running program from C64 RAM and add to library.
        If end_addr is None, we might need to guess or read pointers (e.g. 45/46 for BASIC end).
        """
        if not metadata:
            metadata = {"title": "Unknown Capture", "year": "Unknown"}

        # 1. Determine Size
        # For simplicity, let's assume we read standard C64 RAM 64K or specific range
        # A better approach is reading 2D/2E (Start of Variables) or 45/46 (End of Basic)
        # But reading pointers from Python via FPGA peek is slow.
        # Let's assume the user or UI provides the range, or we dump full 64K.
        
        if end_addr is None:
            end_addr = 0xFFFF # Dump everything? Or maybe just up to A000?
            
        size = end_addr - start_addr
        self.logger.info(f"Ingesting RAM {hex(start_addr)}-{hex(end_addr)} ({size} bytes)...")
        
        # 2. Read Memory
        # Use the fast block read if available
        try:
            data = self.fpga.read_block(start_addr, size)
        except Exception as e:
            self.logger.error(f"Failed to read RAM: {e}")
            return False

        # 3. Add header (PRG requires first 2 bytes to be load address)
        # If we read from 0801, we should prepend 01 08
        load_addr_bytes = start_addr.to_bytes(2, byteorder='little')
        file_data = load_addr_bytes + data

        # 4. Save to DB
        item_id = self.db.add_item(metadata, file_data)
        
        if item_id:
            self.logger.info(f"Item saved with ID {item_id}. Starting AI enrichment...")
            # 5. Trigger AI
            self.ai.enrich_item_async(item_id, metadata)
            return True
        
        return False

    def ingest_file(self, source_path, metadata):
        """Ingest an existing file (e.g. from USB stick or download)"""
        try:
            with open(source_path, 'rb') as f:
                data = f.read()
            
            item_id = self.db.add_item(metadata, data)
            if item_id:
                self.ai.enrich_item_async(item_id, metadata)
                return True
        except Exception as e:
            self.logger.error(f"File ingest failed: {e}")
            return False

    def get_virtual_listing(self, path):
        """
        Generates a directory listing for the Virtual Drive based on DB queries.
        Path format: //LIB/CATEGORY/VALUE
        """
        parts = [p for p in path.split('/') if p] # Remove empty strings
        
        # Root: //LIB -> Show Categories
        if len(parts) <= 1: # "LIB"
            return [
                ("DIR", "ALL GAMES"),
                ("DIR", "BY YEAR"),
                ("DIR", "BY GENRE"),
                ("DIR", "FAVORITES")
            ]
            
        category = parts[1]
        
        if category == "ALL GAMES":
            items = self.db.search()
            return [("PRG", i['title'], i['id']) for i in items]
            
        elif category == "BY YEAR":
            if len(parts) == 2:
                # List Years
                # TODO: Get distinct years from DB
                return [("DIR", "1985"), ("DIR", "1986"), ("DIR", "1987")] # Placeholder
            else:
                year = parts[2]
                items = self.db.search(year=year)
                return [("PRG", i['title'], i['id']) for i in items]

        elif category == "BY GENRE":
            if len(parts) == 2:
                genres = self.db.get_genres()
                return [("DIR", g) for g in genres]
            else:
                genre = parts[2]
                items = self.db.search(genre=genre)
                return [("PRG", i['title'], i['id']) for i in items]
                
        return []

