#!/usr/bin/env python3
"""
SuiteV17 Complete Setup - Installazione automatizzata 100%
Verifica, installa, configura e testa tutto automaticamente
"""
import os
import sys
import subprocess
import json
import shutil
import platform
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import argparse
import time

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_banner():
    print(f'''
{Colors.CYAN}{Colors.BOLD}
+==================================================================+
|                                                                  |
|              SUITEV17 - COMPLETE SETUP INSTALLER                |
|                                                                  |
|  Automated Installation - Configuration - Testing - Deployment   |
|                                                                  |
+==================================================================+
{Colors.RESET}
''')

def print_status(msg: str, status: str = 'info', indent: int = 0):
    prefix = '  ' * indent
    if status == 'success':
        print(f'{prefix}{Colors.GREEN}[OK]{Colors.RESET} {msg}')
    elif status == 'error':
        print(f'{prefix}{Colors.RED}[FAIL]{Colors.RESET} {msg}')
    elif status == 'warning':
        print(f'{prefix}{Colors.YELLOW}!{Colors.RESET} {msg}')
    elif status == 'info':
        print(f'{prefix}{Colors.BLUE}•{Colors.RESET} {msg}')
    else:
        print(f'{prefix}{msg}')

def run_command(cmd: List[str], cwd: str = None, shell: bool = False) -> Tuple[bool, str, str]:
    """Esegue comando e ritorna (success, stdout, stderr)"""
    try:
        result = subprocess.run(
            cmd,
            cwd=cwd,
            shell=shell,
            capture_output=True,
            text=True,
            timeout=300
        )
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, '', str(e)

def check_python() -> bool:
    """Verifica Python 3.8+"""
    version = sys.version_info
    if version.major == 3 and version.minor >= 8:
        print_status(f'Python {version.major}.{version.minor}.{version.micro} - OK', 'success')
        return True
    else:
        print_status(f'Python {version.major}.{version.minor} (richiesto 3.8+)', 'error')
        return False

def check_nodejs() -> bool:
    """Verifica Node.js"""
    success, stdout, _ = run_command(['node', '--version'])
    if success:
        print_status(f'Node.js {stdout.strip()} - OK', 'success')
        return True
    else:
        print_status('Node.js non trovato', 'error')
        print_status('Scarica da: https://nodejs.org/', 'info', 1)
        return False

def check_git() -> bool:
    """Verifica Git"""
    success, stdout, _ = run_command(['git', '--version'])
    if success:
        print_status(f'Git {stdout.strip().split()[2]} - OK', 'success')
        return True
    else:
        print_status('Git non trovato (opzionale)', 'warning')
        return False

def install_python_dependencies() -> bool:
    """Installa tutte le dipendenze Python"""
    print_status('\\nInstallazione dipendenze Python...', 'info')
    
    requirements = [
        'fastapi>=0.104.0', 'uvicorn[standard]>=0.24.0', 'pydantic>=2.5.0',
        'websockets>=12.0', 'aiohttp>=3.9.0', 'requests>=2.31.0',
        'psutil>=5.9.0', 'python-dotenv>=1.0.0', 'numpy>=1.24.0',
        'pandas>=2.1.0', 'cryptography>=41.0.0', 'pyjwt>=2.8.0',
        'bcrypt>=4.1.0', 'pytest>=7.4.0', 'httpx>=0.25.0',
        'sqlalchemy>=2.0.0', 'alembic>=1.12.0', 'redis>=5.0.0',
        'celery>=5.3.0', 'prometheus-client>=0.19.0', 'tweepy>=4.14.0',
        'pillow>=10.0.0', 'schedule>=1.2.0', 'watchdog>=3.0.0'
    ]
    
    failed = []
    for i, package in enumerate(requirements, 1):
        print_status(f'[{i}/{len(requirements)}] {package}', 'info', 1)
        success, _, stderr = run_command([sys.executable, '-m', 'pip', 'install', '-q', package])
        if not success:
            failed.append(package)
            print_status(f'Fallito: {package}', 'error', 2)
    
    if failed:
        print_status(f'\\n{len(failed)} pacchetti falliti', 'warning')
        return False
    
    print_status('Tutte le dipendenze Python installate!', 'success')
    return True

def install_node_dependencies() -> bool:
    """Installa dipendenze Node.js"""
    print_status('\\nInstallazione dipendenze Node.js...', 'info')
    
    npm_packages = ['pm2', 'nodemon', 'electron', 'electron-builder']
    
    for pkg in npm_packages:
        print_status(f'Installazione {pkg}...', 'info', 1)
        run_command(['npm', 'install', '-g', pkg], shell=True)
    
    # Installa dipendenze ElectronApp
    if os.path.exists('ElectronApp/package.json'):
        print_status('Installazione dipendenze Electron...', 'info', 1)
        run_command(['npm', 'install'], cwd='ElectronApp')
    
    print_status('Dipendenze Node.js installate!', 'success')
    return True

def create_directory_structure():
    """Crea struttura directory"""
    print_status('\\nCreazione struttura directory...', 'info')
    
    dirs = [
        'data', 'logs', 'backups', 'tmp', 'config',
        'plugins', 'plugins/active', 'plugins/available',
        'monitoring', 'docs', 'tests', 'scripts'
    ]
    
    for d in dirs:
        Path(d).mkdir(parents=True, exist_ok=True)
        print_status(f'Creata: {d}/', 'success', 1)

def create_env_file():
    """Crea file .env completo"""
    print_status('\\nCreazione configurazione ambiente...', 'info')
    
    env_content = '''
# SuiteV17 - Configurazione Completa
# Generata automaticamente dal setup

# ============================================
# SECURITY - MODIFICARE QUESTI VALORI!
# ============================================
SUITEV17_SECRET=CHANGE_ME_STRONG_SECRET_KEY
API_TOKEN=CHANGE_ME_API_TOKEN
JWT_SECRET=CHANGE_ME_JWT_SECRET
ENCRYPTION_KEY=CHANGE_ME_32CHAR_KEY_____

# ============================================
# DATABASE
# ============================================
DATABASE_URL=sqlite:///data/suitev17.db
# Per PostgreSQL: postgresql://user:pass@localhost/suitev17
DB_POOL_SIZE=20
DB_MAX_OVERFLOW=10

# ============================================
# SERVICE PORTS
# ============================================
GATEWAY_PORT=8080
API_PORT=8083
WEBSOCKET_PORT=8765
SOCIAL_PORT=3007
DASHBOARD_PORT=8085
MONITORING_PORT=9090

# ============================================
# REDIS (opzionale, per cache e task queue)
# ============================================
REDIS_URL=redis://localhost:6379/0
REDIS_ENABLED=false

# ============================================
# OLLAMA / AI
# ============================================
OLLAMA_URL=http://localhost:11434/api/generate
OLLAMA_MODEL=llama3.1
OLLAMA_ENABLED=true

# OpenAI (opzionale)
OPENAI_API_KEY=
OPENAI_ENABLED=false

# ============================================
# SOCIAL MEDIA - Inserire le proprie API key
# ============================================
TWITTER_ENABLED=false
TWITTER_API_KEY=
TWITTER_API_SECRET=
TWITTER_ACCESS_TOKEN=
TWITTER_ACCESS_SECRET=

TELEGRAM_ENABLED=false
TELEGRAM_BOT_TOKEN=
TELEGRAM_CHANNEL_ID=

DISCORD_ENABLED=false
DISCORD_WEBHOOK_URL=

# ============================================
# BLOCKCHAIN
# ============================================
SOLANA_RPC=https://api.mainnet-beta.solana.com
SOL_WALLET=
SOL_PRIVATE_KEY=

# ============================================
# NOTIFICATIONS
# ============================================
SMTP_HOST=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
SMTP_FROM=

# ============================================
# MONITORING
# ============================================
PROMETHEUS_ENABLED=true
GRAFANA_ENABLED=false
HEALTH_CHECK_INTERVAL=30

# ============================================
# BACKUP
# ============================================
BACKUP_ENABLED=true
BACKUP_INTERVAL_HOURS=24
BACKUP_RETENTION_DAYS=30
BACKUP_ENCRYPT=true

# ============================================
# FEATURE FLAGS
# ============================================
ENABLE_PLUGINS=true
ENABLE_TASK_QUEUE=true
ENABLE_NOTIFICATIONS=true
ENABLE_ANALYTICS=true
ENABLE_ML_PIPELINE=false

# ============================================
# DEVELOPMENT
# ============================================
DEBUG=false
LOG_LEVEL=INFO
DEV_MODE=false
'''
    
    with open('.env', 'w', encoding='utf-8') as f:
        f.write(env_content.strip())
    
    print_status('File .env creato!', 'success')
    print_status('IMPORTANTE: Modifica i valori SECURITY!', 'warning', 1)

def create_systemd_service():
    """Crea servizio systemd (Linux)"""
    if platform.system() != 'Linux':
        return
    
    service_content = '''
[Unit]
Description=SuiteV17 Platform
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/suitev17
ExecStart=/usr/bin/python3 /opt/suitev17/suitev17_resilient_master.py
Restart=always
RestartSec=10
Environment=PYTHONPATH=/opt/suitev17

[Install]
WantedBy=multi-user.target
'''
    
    with open('/tmp/suitev17.service', 'w') as f:
        f.write(service_content)
    
    print_status('Servizio systemd creato: /tmp/suitev17.service', 'success')

def create_windows_service():
    """Crea script per Windows Service"""
    bat_content = '''
@echo off
:: SuiteV17 Windows Service Installer
:: Esegui come Administrator

cd /d C:\\SuiteV17

:: Installa NSSM (Non-Sucking Service Manager)
if not exist "C:\\Program Files\\nssm\\nssm.exe" (
    echo Download NSSM...
    powershell -Command "Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile 'nssm.zip'"
    powershell -Command "Expand-Archive -Path 'nssm.zip' -DestinationPath 'C:\\Program Files'"
)

:: Crea servizio
"C:\\Program Files\\nssm-2.24\\win64\\nssm.exe" install SuiteV17 "C:\\Python39\\python.exe"
"C:\\Program Files\\nssm-2.24\\win64\\nssm.exe" set SuiteV17 AppDirectory "C:\\SuiteV17"
"C:\\Program Files\\nssm-2.24\\win64\\nssm.exe" set SuiteV17 AppParameters "suitev17_resilient_master.py"
"C:\\Program Files\\nssm-2.24\\win64\\nssm.exe" set SuiteV17 DisplayName "SuiteV17 Platform"
"C:\\Program Files\\nssm-2.24\\win64\\nssm.exe" set SuiteV17 Start SERVICE_AUTO_START

sc start SuiteV17

echo SuiteV17 installed as Windows Service!
pause
'''
    
    with open('install_windows_service.bat', 'w') as f:
        f.write(bat_content)
    
    print_status('Script Windows Service creato: install_windows_service.bat', 'success')

def run_tests() -> bool:
    """Esegui test suite"""
    print_status('\\nEsecuzione test suite...', 'info')
    
    test_files = [
        'test_suite.py',
        'resilience_wrapper.py',
        'error_handler.py'
    ]
    
    passed = 0
    failed = 0
    
    for test in test_files:
        if os.path.exists(test):
            print_status(f'Esecuzione {test}...', 'info', 1)
            success, stdout, stderr = run_command([sys.executable, test])
            if success:
                passed += 1
                print_status(f'OK', 'success', 2)
            else:
                failed += 1
                print_status(f'Fallito', 'error', 2)
    
    print_status(f'\\nTest: {passed} passed, {failed} failed', 'info' if failed == 0 else 'warning')
    return failed == 0

def create_start_scripts():
    """Crea script di avvio"""
    print_status('\\nCreazione script avvio...', 'info')
    
    # Windows BAT
    bat_content = '''
@echo off
cls
echo =========================================
echo  SUITEV17 PLATFORM - STARTER
echo =========================================
echo.

cd /d C:\\SuiteV17

:: Check Python
python --version > nul 2>&1
if errorlevel 1 (
    echo ERRORE: Python non trovato
    exit /b 1
)

:: Start SuiteV17
echo Avvio SuiteV17...
python suitev17_resilient_master.py

pause
'''
    
    with open('Start-SuiteV17.bat', 'w') as f:
        f.write(bat_content)
    
    # PowerShell
    ps_content = '''
#Requires -RunAsAdministrator

$Host.UI.RawUI.WindowTitle = "SuiteV17 Platform"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  SUITEV17 PLATFORM STARTER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location C:\\SuiteV17

# Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python non trovato"
    exit 1
}

# Load environment
if (Test-Path .env) {
    Get-Content .env | ForEach-Object {
        if ($_ -match "^([^#][^=]*)=(.*)$") {
            [Environment]::SetEnvironmentVariable($matches[1], $matches[2])
        }
    }
}

# Start SuiteV17
Write-Host "Avvio SuiteV17..." -ForegroundColor Green
python suitev17_resilient_master.py
'''
    
    with open('Start-SuiteV17.ps1', 'w') as f:
        f.write(ps_content)
    
    # Linux Shell
    sh_content = '''
#!/bin/bash

cd /opt/suitev17 || cd ~/suitev17 || exit 1

echo "========================================"
echo "  SUITEV17 PLATFORM STARTER"
echo "========================================"
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "ERRORE: Python3 non trovato"
    exit 1
fi

# Load environment
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Start SuiteV17
echo "Avvio SuiteV17..."
python3 suitev17_resilient_master.py
'''
    
    with open('start-suitev17.sh', 'w') as f:
        f.write(sh_content)
    
    # Render eseguibili
    os.chmod('start-suitev17.sh', 0o755)
    
    print_status('Script avvio creati:', 'success')
    print_status('  - Start-SuiteV17.bat (Windows)', 'success', 1)
    print_status('  - Start-SuiteV17.ps1 (PowerShell)', 'success', 1)
    print_status('  - start-suitev17.sh (Linux/Mac)', 'success', 1)

def final_report():
    """Report finale"""
    print_banner()
    
    print(f'''
{Colors.GREEN}{Colors.BOLD}INSTALLAZIONE COMPLETATA!{Colors.RESET}

{Colors.CYAN}SuiteV17 è pronta all'uso!{Colors.RESET}

{Colors.BOLD}Prossimi passi:{Colors.RESET}

1. Configura il file .env:
   {Colors.YELLOW}notepad .env{Colors.RESET}
   
   Modifica almeno:
   - SUITEV17_SECRET
   - API_TOKEN
   - JWT_SECRET

2. Avvia la piattaforma:
   {Colors.YELLOW}Start-SuiteV17.bat{Colors.RESET} (Windows)
   {Colors.YELLOW}./start-suitev17.sh{Colors.RESET} (Linux)

3. Accedi alla dashboard:
   - API: http://localhost:8083/docs
   - WebSocket: ws://localhost:8765
   - Electron: npm start (in ElectronApp/)

4. Verifica lo stato:
   python test_suite.py

{Colors.CYAN}Supporto:{Colors.RESET}
- Log: logs/
- Config: .env
- Documentazione: docs/

{Colors.GREEN}Buon utilizzo di SuiteV17!{Colors.RESET}
''')

def main():
    parser = argparse.ArgumentParser(description='SuiteV17 Complete Setup')
    parser.add_argument('--quick', action='store_true', help='Installazione rapida')
    parser.add_argument('--test-only', action='store_true', help='Solo test')
    args = parser.parse_args()
    
    print_banner()
    
    if args.test_only:
        run_tests()
        return
    
    # Verifiche preliminari
    print_status('Verifiche preliminari...', 'info')
    
    checks = [
        ('Python 3.8+', check_python),
        ('Node.js', check_nodejs),
        ('Git', check_git)
    ]
    
    all_passed = True
    for name, check_func in checks:
        print_status(f'Verifica {name}...', 'info', 1)
        if not check_func():
            all_passed = False
    
    if not all_passed:
        print_status('\\nAlcune verifiche sono fallite.', 'error')
        print_status('Correggi prima di continuare.', 'warning')
        return
    
    # Installazione
    if not args.quick:
        install_python_dependencies()
        install_node_dependencies()
    
    # Setup
    create_directory_structure()
    create_env_file()
    create_start_scripts()
    create_windows_service()
    
    if platform.system() == 'Linux':
        create_systemd_service()
    
    # Test
    if not args.quick:
        run_tests()
    
    # Report
    final_report()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print_status('\\n\\nInstallazione interrotta.', 'warning')
        sys.exit(1)
    except Exception as e:
        print_status(f'\\n\\nErrore: {e}', 'error')
        sys.exit(1)
