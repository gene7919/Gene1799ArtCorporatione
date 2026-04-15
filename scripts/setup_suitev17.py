#!/usr/bin/env python3
"""
SuiteV17 Setup - Configurazione automatica con verifica resilienza
"""
import os
import sys
import subprocess
import json
from pathlib import Path
from typing import Dict, List, Tuple
import argparse

class Colors:
    GREEN = '\\033[92m'
    RED = '\\033[91m'
    YELLOW = '\\033[93m'
    BLUE = '\\033[94m'
    RESET = '\\033[0m'

def print_status(message: str, status: str = 'info'):
    """Stampa messaggio colorato."""
    if status == 'success':
        print(f'{Colors.GREEN}✓{Colors.RESET} {message}')
    elif status == 'error':
        print(f'{Colors.RED}✗{Colors.RESET} {message}')
    elif status == 'warning':
        print(f'{Colors.YELLOW}!{Colors.RESET} {message}')
    else:
        print(f'{Colors.BLUE}•{Colors.RESET} {message}')

def run_command(cmd: List[str], description: str) -> Tuple[bool, str]:
    """Esegue comando e ritorna risultato."""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=60
        )
        if result.returncode == 0:
            return True, result.stdout
        else:
            return False, result.stderr
    except Exception as e:
        return False, str(e)

def check_python_version() -> bool:
    """Verifica versione Python."""
    version = sys.version_info
    if version.major == 3 and version.minor >= 8:
        print_status(f'Python {version.major}.{version.minor}.{version.micro}', 'success')
        return True
    else:
        print_status(f'Python {version.major}.{version.minor} (richiesto 3.8+)', 'error')
        return False

def check_dependencies() -> Dict[str, bool]:
    """Verifica dipendenze."""
    required = [
        'fastapi', 'pydantic', 'uvicorn', 'websockets', 'aiohttp',
        'requests', 'psutil', 'sqlite3'
    ]
    
    results = {}
    for module in required:
        try:
            __import__(module)
            results[module] = True
            print_status(f'{module} installato', 'success')
        except ImportError:
            results[module] = False
            print_status(f'{module} mancante', 'warning')
            
    return results

def install_dependencies() -> bool:
    """Installa dipendenze."""
    print_status('Installazione dipendenze Python...', 'info')
    
    requirements = [
        'fastapi>=0.104.0',
        'uvicorn[standard]>=0.24.0',
        'pydantic>=2.5.0',
        'websockets>=12.0',
        'aiohttp>=3.9.0',
        'requests>=2.31.0',
        'psutil>=5.9.0',
        'python-dotenv>=1.0.0',
        'numpy>=1.24.0',
        'tweepy>=4.14.0'
    ]
    
    success = True
    for package in requirements:
        print_status(f'Installazione {package}...', 'info')
        ok, output = run_command([sys.executable, '-m', 'pip', 'install', package], package)
        if ok:
            print_status(f'{package} installato', 'success')
        else:
            print_status(f'{package} fallito: {output}', 'error')
            success = False
            
    return success

def create_directories():
    """Crea directory necessarie."""
    dirs = [
        'data',
        'logs',
        'backups',
        'tmp',
        'config'
    ]
    
    for dir_name in dirs:
        Path(dir_name).mkdir(exist_ok=True)
        print_status(f'Directory {dir_name}/ creata', 'success')

def check_files() -> List[str]:
    """Verifica file necessari."""
    required_files = [
        'suitev17_resilient_master.py',
        'error_handler.py',
        'suitev17_logger.py',
        'health_monitor.py',
        'graceful_shutdown.py',
        'resilient_database.py',
        'resilience_wrapper.py'
    ]
    
    missing = []
    for file in required_files:
        if Path(file).exists():
            print_status(f'{file} presente', 'success')
        else:
            print_status(f'{file} mancante', 'error')
            missing.append(file)
            
    return missing

def run_resilience_tests() -> bool:
    """Esegue test resilienza."""
    print_status('\\nEsecuzione test resilienza...', 'info')
    
    tests = [
        ('error_handler', 'error_handler'),
        ('suitev17_logger', 'suitev17_logger'),
        ('resilient_database', 'resilient_database'),
    ]
    
    all_passed = True
    for module_name, import_name in tests:
        try:
            __import__(import_name)
            print_status(f'{module_name} import OK', 'success')
        except Exception as e:
            print_status(f'{module_name} import FAIL: {e}', 'error')
            all_passed = False
            
    return all_passed

def create_env_file():
    """Crea file .env se non esiste."""
    if Path('.env').exists():
        print_status('.env già esistente', 'success')
        return
        
    env_content = '''
# SuiteV17 Configuration
SUITEV17_SECRET=change_me_in_production
API_TOKEN=test-token-change-in-production

# Database
DB_PATH=./data/suitev17.db
BACKUP_DIR=./backups

# Ports
API_PORT=8083
WEBSOCKET_PORT=8765
SOCIAL_PORT=3007
GATEWAY_PORT=8080

# Services
OLLAMA_URL=http://localhost:11434/api/generate
OLLAMA_MODEL=llama3.1

# Optional: Social Media
# TWITTER_ENABLED=true
# TWITTER_API_KEY=your_key

# Optional: Blockchain
# SOL_WALLET=your_wallet
# SOLANA_RPC=https://api.mainnet-beta.solana.com
'''
    
    with open('.env', 'w') as f:
        f.write(env_content.strip())
        
    print_status('.env creato', 'success')

def main():
    """Setup principale."""
    parser = argparse.ArgumentParser(description='SuiteV17 Setup')
    parser.add_argument('--install-deps', action='store_true', help='Installa dipendenze')
    parser.add_argument('--test', action='store_true', help='Esegui solo test')
    args = parser.parse_args()
    
    print('=' * 70)
    print('SUITEV17 SETUP')
    print('=' * 70)
    print()
    
    if args.test:
        print_status('MODALITA TEST', 'info')
        run_resilience_tests()
        return
        
    # Verifiche preliminari
    print_status('Verifica Python...', 'info')
    if not check_python_version():
        sys.exit(1)
        
    # Crea directory
    print_status('\\nCreazione directory...', 'info')
    create_directories()
    
    # Verifica/Installa dipendenze
    print_status('\\nVerifica dipendenze...', 'info')
    deps = check_dependencies()
    
    if args.install_deps or not all(deps.values()):
        if not install_dependencies():
            print_status('Installazione dipendenze fallita', 'error')
            sys.exit(1)
            
    # Verifica file
    print_status('\\nVerifica file...', 'info')
    missing = check_files()
    if missing:
        print_status(f'Mancano {len(missing)} file critici', 'error')
        sys.exit(1)
        
    # Crea .env
    print_status('\\nConfigurazione ambiente...', 'info')
    create_env_file()
    
    # Test resilienza
    print_status('\\nTest resilienza...', 'info')
    if run_resilience_tests():
        print_status('Tutti i test passati!', 'success')
    else:
        print_status('Alcuni test falliti', 'warning')
        
    # Riepilogo
    print()
    print('=' * 70)
    print('SETUP COMPLETATO')
    print('=' * 70)
    print()
    print('Per avviare SuiteV17:')
    print('  python suitev17_resilient_master.py')
    print()
    print('Oppure usa il launcher:')
    print('  python launcher.py')
    print()
    print('Per testare la resilienza:')
    print('  python test_suite.py')

if __name__ == '__main__':
    main()
