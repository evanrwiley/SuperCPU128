import sqlite3
import os
import json
import logging
from datetime import datetime

DB_PATH = os.path.join(os.path.dirname(__file__), '../../data/library.db')
STORAGE_PATH = os.path.join(os.path.dirname(__file__), '../../data/storage')

class LibraryDatabase:
    def __init__(self):
        self.logger = logging.getLogger("LibraryDB")
        self._ensure_paths()
        self._init_db()

    def _ensure_paths(self):
        if not os.path.exists(os.path.dirname(DB_PATH)):
            os.makedirs(os.path.dirname(DB_PATH))
        if not os.path.exists(STORAGE_PATH):
            os.makedirs(STORAGE_PATH)

    def _init_db(self):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        # Main Items Table
        c.execute('''CREATE TABLE IF NOT EXISTS items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            filename TEXT NOT NULL,
            file_path TEXT NOT NULL,
            file_size INTEGER,
            file_type TEXT, -- PRG, D64, T64, CRT
            year INTEGER,
            publisher TEXT,
            developer TEXT,
            genre TEXT,
            sub_genre TEXT,
            description TEXT,
            ai_summary TEXT,
            ai_tags TEXT, -- JSON array
            tosec_id TEXT,
            added_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            play_count INTEGER DEFAULT 0,
            favorite BOOLEAN DEFAULT 0
        )''')
        
        # Categories/Tags mapping (Optional normalization, but keeping simple for now)
        
        conn.commit()
        conn.close()

    def add_item(self, metadata, file_data):
        """
        metadata: dict containing title, year, etc.
        file_data: binary content
        """
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        
        # Generate safe filename/storage path
        # Using timestamp + safe title to avoid collisions
        safe_title = "".join([c for c in metadata.get('title', 'unknown') if c.isalnum() or c in (' ', '-', '_')]).strip()
        storage_filename = f"{int(datetime.now().timestamp())}_{safe_title}.{metadata.get('extension', 'prg')}"
        full_path = os.path.join(STORAGE_PATH, storage_filename)
        
        # Write file
        try:
            with open(full_path, 'wb') as f:
                f.write(file_data)
        except Exception as e:
            self.logger.error(f"Failed to write file: {e}")
            return None

        # Insert DB Record
        try:
            c.execute('''INSERT INTO items (
                title, filename, file_path, file_size, file_type, 
                year, publisher, genre, description, ai_tags
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''', (
                metadata.get('title'),
                metadata.get('filename', safe_title),
                storage_filename, # Store relative path
                len(file_data),
                metadata.get('file_type', 'PRG'),
                metadata.get('year'),
                metadata.get('publisher'),
                metadata.get('genre'),
                metadata.get('description'),
                json.dumps(metadata.get('tags', []))
            ))
            item_id = c.lastrowid
            conn.commit()
            return item_id
        except Exception as e:
            self.logger.error(f"DB Insert failed: {e}")
            return None
        finally:
            conn.close()

    def update_ai_metadata(self, item_id, ai_data):
        """Update record with AI enriched data"""
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute('''UPDATE items SET 
            ai_summary = ?, 
            ai_tags = ?,
            description = COALESCE(description, ?) -- Only update description if empty
            WHERE id = ?''', (
                ai_data.get('summary'),
                json.dumps(ai_data.get('tags', [])),
                ai_data.get('description'),
                item_id
            ))
        conn.commit()
        conn.close()

    def get_item(self, item_id):
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        c.execute("SELECT * FROM items WHERE id = ?", (item_id,))
        row = c.fetchone()
        conn.close()
        return dict(row) if row else None

    def search(self, query=None, genre=None, year=None, favorite=None):
        conn = sqlite3.connect(DB_PATH)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        
        sql = "SELECT id, title, year, genre, file_type FROM items WHERE 1=1"
        params = []
        
        if query:
            sql += " AND title LIKE ?"
            params.append(f"%{query}%")
        if genre:
            sql += " AND genre LIKE ?"
            params.append(f"%{genre}%")
        if year:
            sql += " AND year = ?"
            params.append(year)
        if favorite:
            sql += " AND favorite = 1"
            
        sql += " ORDER BY title ASC"
        
        c.execute(sql, params)
        rows = c.fetchall()
        conn.close()
        return [dict(r) for r in rows]

    def get_genres(self):
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("SELECT DISTINCT genre FROM items WHERE genre IS NOT NULL ORDER BY genre")
        rows = c.fetchall()
        conn.close()
        return [r[0] for r in rows]

