#!/usr/bin/env python3
"""
SuiteV17 File Watcher Module
Monitors file changes and calculates hashes for cache invalidation
"""
import os
import hashlib
import time
from pathlib import Path
from typing import Dict, Optional
from datetime import datetime

class FileWatcher:
    """Watches files for changes and tracks their state."""
    
    def __init__(self, watch_dir: str = None):
        self.watch_dir = watch_dir or os.getcwd()
        self.file_states: Dict[str, Dict] = {}
        
    def calculate_hash(self, filepath: str) -> Optional[str]:
        """Calculate SHA256 hash of file contents."""
        try:
            with open(filepath, 'rb') as f:
                return hashlib.sha256(f.read()).hexdigest()
        except Exception as e:
            print(f'Error hashing {filepath}: {e}')
            return None
    
    def scan_directory(self, pattern: str = '*.py') -> Dict[str, str]:
        """Scan directory and return file hashes."""
        results = {}
        for filepath in Path(self.watch_dir).rglob(pattern):
            if filepath.is_file():
                file_hash = self.calculate_hash(str(filepath))
                if file_hash:
                    results[str(filepath)] = file_hash
        return results
    
    def get_file_info(self, filepath: str) -> Optional[Dict]:
        """Get file information including size, mtime, hash."""
        try:
            stat = os.stat(filepath)
            return {
                'path': filepath,
                'size': stat.st_size,
                'mtime': stat.st_mtime,
                'hash': self.calculate_hash(filepath),
                'checked_at': datetime.now().isoformat()
            }
        except Exception as e:
            return None

def calculate_hash(filepath: str) -> Optional[str]:
    """Standalone function for calculating file hash."""
    watcher = FileWatcher()
    return watcher.calculate_hash(filepath)

if __name__ == '__main__':
    # Test
    watcher = FileWatcher()
    print('FileWatcher module loaded successfully')
    
    # Test hash calculation
    import glob
    for f in glob.glob('*.py')[:3]:
        h = watcher.calculate_hash(f)
        print(f'{f}: {h[:16]}...' if h else f'{f}: ERROR')
