#!/usr/bin/env python3
"""
Script di auto-installazione per dipendenze Python e configurazioni comuni
Auto-installation script for Python dependencies and common configurations
"""

import subprocess
import sys
import os
import json
import requests
from pathlib import Path

class AutoInstaller:
    def __init__(self):
        self.python_cmd = sys.executable
        
    def run_command(self, command, check=True):
        """Esegue un comando shell"""
        try:
            result = subprocess.run(command, shell=True, check=check, 
                                  capture_output=True, text=True)
            print(f"✓ {command}")
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"✗ Errore: {command}")
            print(f"  {e.stderr}")
            return None
    
    def install_package(self, package):
        """Installa un pacchetto Python"""
        return self.run_command(f"{self.python_cmd} -m pip install {package}")
    
    def install_common_packages(self):
        """Installa pacchetti Python comuni"""
        packages = [
            "requests",
            "numpy",
            "pandas", 
            "matplotlib",
            "seaborn",
            "beautifulsoup4",
            "selenium",
            "flask",
            "fastapi",
            "uvicorn",
            "python-dotenv",
            "pydantic",
            "click",
            "rich",
            "tqdm"
        ]
        
        print("Installazione pacchetti Python comuni...")
        for package in packages:
            self.install_package(package)
    
    def setup_git_config(self):
        """Configura Git con valori di base"""
        print("Configurazione Git...")
        # Questi sono esempi - modifica con i tuoi dati
        self.run_command('git config --global user.name "Your Name"', check=False)
        self.run_command('git config --global user.email "your.email@example.com"', check=False)
        self.run_command('git config --global init.defaultBranch main', check=False)
    
    def create_project_structure(self, project_name="nuovo_progetto"):
        """Crea una struttura di progetto standard"""
        print(f"Creazione struttura progetto: {project_name}")
        
        folders = [
            f"{project_name}",
            f"{project_name}/src",
            f"{project_name}/tests",
            f"{project_name}/docs",
            f"{project_name}/data",
            f"{project_name}/config"
        ]
        
        for folder in folders:
            Path(folder).mkdir(parents=True, exist_ok=True)
            
        # Crea file di base
        files = {
            f"{project_name}/README.md": f"# {project_name}\n\nDescrizione del progetto.\n",
            f"{project_name}/.gitignore": """__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.env
.venv
""",
            f"{project_name}/requirements.txt": """requests>=2.28.0
python-dotenv>=0.19.0
""",
            f"{project_name}/src/__init__.py": "",
            f"{project_name}/tests/__init__.py": "",
            f"{project_name}/config/settings.py": '''"""Configurazioni del progetto"""
import os
from dotenv import load_dotenv

load_dotenv()

DEBUG = os.getenv("DEBUG", "False").lower() == "true"
DATABASE_URL = os.getenv("DATABASE_URL", "")
'''
        }
        
        for file_path, content in files.items():
            Path(file_path).write_text(content, encoding='utf-8')
    
    def fix_json_encoding(self, file_path):
        """Corregge problemi di encoding nei file JSON"""
        try:
            with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                content = f.read()
            
            # Rimuove caratteri problematici
            content = content.encode('utf-8', errors='ignore').decode('utf-8')
            
            # Verifica che sia JSON valido
            json.loads(content)
            
            # Riscrive il file pulito
            with open(file_path + '.fixed', 'w', encoding='utf-8') as f:
                f.write(content)
                
            print(f"✓ File JSON corretto: {file_path}.fixed")
            return True
            
        except Exception as e:
            print(f"✗ Errore correzione JSON: {e}")
            return False

def main():
    installer = AutoInstaller()
    
    print("=== AUTO INSTALLER ===")
    print("1. Installa pacchetti comuni")
    print("2. Configura Git")  
    print("3. Crea struttura progetto")
    print("4. Correggi file JSON")
    print("5. Tutto")
    
    choice = input("Scegli opzione (1-5): ").strip()
    
    if choice == "1" or choice == "5":
        installer.install_common_packages()
    
    if choice == "2" or choice == "5":
        installer.setup_git_config()
    
    if choice == "3" or choice == "5":
        project_name = input("Nome progetto (default: nuovo_progetto): ").strip()
        if not project_name:
            project_name = "nuovo_progetto"
        installer.create_project_structure(project_name)
    
    if choice == "4":
        file_path = input("Percorso file JSON da correggere: ").strip()
        if file_path and os.path.exists(file_path):
            installer.fix_json_encoding(file_path)
    
    print("\n✓ Installazione completata!")

if __name__ == "__main__":
    main()
