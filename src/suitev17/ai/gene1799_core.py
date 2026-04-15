#!/usr/bin/env python3
"""Gene1799 Ultra - Core Component"""

import json
import os
from pathlib import Path
from datetime import datetime

class Gene1799Core:
    """Sistema core Gene1799"""
    
    def __init__(self):
        self.version = "1.0.0"
        self.base_dir = Path(__file__).parent
        self.config = self.load_config()
        
    def load_config(self):
        """Carica configurazione"""
        config_file = self.base_dir / "Config" / "config.json"
        if config_file.exists():
            with open(config_file, 'r') as f:
                return json.load(f)
        return {}
    
    def run(self):
        """Avvia sistema"""
        print(f"Gene1799 Ultra v{self.version}")
        print(f"Sistema avviato: {datetime.now()}")
        print(f"Directory: {self.base_dir}")
        print("\nSistema operativo...")
        
if __name__ == '__main__':
    core = Gene1799Core()
    core.run()
