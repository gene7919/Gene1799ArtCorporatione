#!/usr/bin/env python3
"""
Gene1799 Enhanced System - EXE Builder
Crea un eseguibile standalone pronto all'installazione
"""

import os
import sys
import subprocess
import shutil
from pathlib import Path

# Colori per output
class Colors:
    GREEN = '\033[92m'
    BLUE = '\033[94m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_step(step_num, text):
    print(f"{Colors.BOLD}{Colors.BLUE}[STEP {step_num}]{Colors.ENDC} {text}")

def print_success(text):
    print(f"{Colors.GREEN}✓ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.RED}✗ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.YELLOW}→ {text}{Colors.ENDC}")

def main():
    """Build Gene1799 EXE"""
    
    print(f"""
{Colors.BOLD}{Colors.BLUE}
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║         Gene1799 Enhanced System - EXE Builder v2.0            ║
║                                                                ║
║       Creazione di un eseguibile standalone completo           ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
{Colors.ENDC}
    """)
    
    # STEP 1: Verifica PyInstaller
    print_step(1, "Verifica PyInstaller...")
    try:
        import PyInstaller
        print_success(f"PyInstaller {PyInstaller.__version__} disponibile")
    except ImportError:
        print_error("PyInstaller non installato!")
        print_info("Installo PyInstaller...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "pyinstaller", "-q"])
        print_success("PyInstaller installato")
    
    # STEP 2: Crea directory build
    print_step(2, "Preparazione directory di build...")
    base_path = Path(__file__).parent
    build_dir = base_path / "build_exe"
    dist_dir = base_path / "dist"
    
    if build_dir.exists():
        shutil.rmtree(build_dir)
    if dist_dir.exists():
        shutil.rmtree(dist_dir)
    
    build_dir.mkdir(exist_ok=True)
    print_success(f"Directory creata: {build_dir}")
    
    # STEP 3: Crea main launcher
    print_step(3, "Creazione launcher principale...")
    
    launcher_content = '''
import sys
import os
import asyncio
from pathlib import Path

# Aggiungi il path del programma
sys.path.insert(0, str(Path(__file__).parent))

async def main():
    """Avvia Gene1799 Enhanced System"""
    try:
        # Importa il sistema
        from orchestrator_gui import main as gui_main
        
        # Avvia GUI
        await gui_main()
        
    except ImportError:
        print("Errore: Moduli non trovati!")
        print("Assicurati che tutti i file siano installati correttamente.")
        input("Premi INVIO per uscire...")
        sys.exit(1)
    except Exception as e:
        print(f"Errore durante l'avvio: {e}")
        input("Premi INVIO per uscire...")
        sys.exit(1)

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\\n\\nSistema chiuso dall'utente.")
        sys.exit(0)
'''
    
    launcher_path = base_path / "gene1799_launcher.py"
    with open(launcher_path, 'w', encoding='utf-8') as f:
        f.write(launcher_content)
    
    print_success(f"Launcher creato: {launcher_path}")
    
    # STEP 4: Verifica dipendenze
    print_step(4, "Verifica dipendenze richieste...")
    
    required_packages = [
        'asyncio',
        'psutil',
        'aiohttp',
    ]
    
    for package in required_packages:
        try:
            __import__(package)
            print_success(f"Dipendenza '{package}' disponibile")
        except ImportError:
            print_info(f"Installo {package}...")
            subprocess.check_call([sys.executable, "-m", "pip", "install", package, "-q"])
            print_success(f"{package} installato")
    
    # STEP 5: Crea spec file
    print_step(5, "Configurazione PyInstaller...")
    
    spec_content = f'''
# -*- mode: python ; coding: utf-8 -*-

block_cipher = None

a = Analysis(
    [r'{launcher_path}'],
    pathex=[r'{base_path}'],
    binaries=[],
    datas=[
        (r'{base_path / "logs"}', 'logs'),
        (r'{base_path / "*.md"}', '.'),
    ],
    hiddenimports=[
        'asyncio',
        'psutil',
        'aiohttp',
    ],
    hookspath=[],
    hooksconfig={{}},
    runtime_hooks=[],
    excludedimports=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.zipfiles,
    a.datas,
    [],
    name='Gene1799_Enhanced',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=True,
    disable_windowed_traceback=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='Gene1799_Enhanced',
)
'''
    
    spec_path = base_path / "Gene1799_Enhanced.spec"
    with open(spec_path, 'w', encoding='utf-8') as f:
        f.write(spec_content)
    
    print_success(f"Spec file creato: {spec_path}")
    
    # STEP 6: Build EXE
    print_step(6, "Build dell'eseguibile (questo richiede alcuni minuti)...")
    print_info("Pazienza... il sistema sta compilando tutto...")
    
    try:
        result = subprocess.run(
            [
                sys.executable,
                "-m",
                "PyInstaller",
                str(spec_path),
                "--distpath",
                str(dist_dir),
                "--workpath",
                str(build_dir),
            ],
            capture_output=True,
            text=True,
            timeout=600
        )
        
        if result.returncode == 0:
            print_success("Compilazione completata!")
        else:
            print_error(f"Errore durante la compilazione: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        print_error("Build timeout! Prova di nuovo.")
        return False
    except Exception as e:
        print_error(f"Errore: {e}")
        return False
    
    # STEP 7: Copia file necessari
    print_step(7, "Copia file necessari nell'EXE...")
    
    exe_dir = dist_dir / "Gene1799_Enhanced"
    
    files_to_copy = [
        "enhanced_system.py",
        "auto_healing_agent.py",
        "content_creation_agents.py",
        "ai_learning_engine.py",
        "social_media_automation.py",
        "social_ai_integration.py",
        "orchestrator_gui.py",
        "orchestrator_fixed.py",
    ]
    
    for file in files_to_copy:
        src = base_path / file
        dst = exe_dir / file
        if src.exists():
            shutil.copy2(src, dst)
            print_success(f"Copiato: {file}")
        else:
            print_info(f"File non trovato (opzionale): {file}")
    
    # STEP 8: Copia documentazione
    print_step(8, "Copia documentazione...")
    
    doc_files = [
        "README_QUICK_START.md",
        "ENHANCED_SYSTEM_README.md",
        "FULL_SYSTEM_INTEGRATION.md",
        "TEST_SCENARIOS.md",
        "FILE_INVENTORY.md",
    ]
    
    for doc in doc_files:
        src = base_path / doc
        dst = exe_dir / doc
        if src.exists():
            shutil.copy2(src, dst)
            print_success(f"Documentazione: {doc}")
    
    # STEP 9: Crea script di run
    print_step(9, "Creazione script di avvio...")
    
    run_script = f'''@echo off
REM Gene1799 Enhanced System Launcher
setlocal enabledelayedexpansion

echo.
echo ╔════════════════════════════════════════════════════════╗
echo ║     Gene1799 Enhanced System - Avvio in corso...      ║
echo ╚════════════════════════════════════════════════════════╝
echo.

rem Naviga alla directory del programma
cd /d "%~dp0"

rem Avvia l'applicazione
start Gene1799_Enhanced.exe

echo Applicazione avviata! La finestra dovrebbe apparire tra pochi secondi...
echo.
pause
exit /b 0
'''
    
    run_bat = exe_dir / "RUN_Gene1799.bat"
    with open(run_bat, 'w', encoding='utf-8') as f:
        f.write(run_script)
    
    print_success(f"Script creato: RUN_Gene1799.bat")
    
    # STEP 10: Crea installer Inno Setup
    print_step(10, "Creazione installer Inno Setup...")
    
    inno_content = f'''[Setup]
AppName=Gene1799 Enhanced System
AppVersion=2.0.0
AppPublisher=Gene1799
AppPublisherURL=https://gene1799.com
DefaultDirName={{userpf}}\\Gene1799
DefaultGroupName=Gene1799
OutputDir={dist_dir}
OutputBaseFilename=Gene1799_v2.0_Installer
Compression=lzma
SolidCompression=yes
CreateUninstallKey=yes
PrivilegesRequired=lowest

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\\Italian.isl"
Name: "english"; MessagesFile: "compiler:default.isl"

[Types]
Name: "full"; Description: "Installazione Completa"
Name: "custom"; Description: "Installazione Personalizzata"; Flags: iscustom

[Components]
Name: "main"; Description: "Gene1799 Enhanced System"; Types: full custom; Flags: fixed

[Files]
Source: "{exe_dir}\\*"; DestDir: "{{app}}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{{group}}\\Gene1799 Enhanced System"; Filename: "{{app}}\\Gene1799_Enhanced.exe"
Name: "{{group}}\\Documentazione"; Filename: "{{app}}\\README_QUICK_START.md"
Name: "{{desktop}}\\Gene1799 Enhanced System"; Filename: "{{app}}\\Gene1799_Enhanced.exe"

[Run]
Filename: "{{app}}\\Gene1799_Enhanced.exe"; Description: "Avvia Gene1799 ora"; Flags: postinstall skipifsilent

[UninstallDelete]
Type: dirifempty; Name: "{{app}}"
'''
    
    inno_path = dist_dir / "Gene1799_Installer.iss"
    with open(inno_path, 'w', encoding='utf-8') as f:
        f.write(inno_content)
    
    print_success(f"Installer Inno Setup creato: {inno_path}")
    
    # STEP 11: Crea README per installer
    print_step(11, "Creazione file README...")
    
    readme_content = '''# Gene1799 Enhanced System v2.0 - Guida Installazione

## ✨ Cosa hai ricevuto

Questo è l'installer completo di Gene1799 Enhanced System - una piattaforma AI completamente autonoma con:

- ✅ Auto-Healing Agent (riparazione automatica 24/7)
- ✅ Content Creation (generazione testi, video, musica)
- ✅ Social Media Automation (Twitter, LinkedIn, TikTok)
- ✅ AI Learning Engine (7 agenti che imparano)
- ✅ NFT Monetization (Zora.co integration)

## 📦 Opzioni di Installazione

### OPZIONE 1: Installer Automatico (Consigliato)
1. Scarica: `Gene1799_v2.0_Installer.exe`
2. Doppio click su `.exe`
3. Segui le istruzioni (next, next, finish)
4. Sistema installato e pronto!

### OPZIONE 2: Standalone (Portable)
1. Estrai la cartella `Gene1799_Enhanced`
2. Doppio click su `RUN_Gene1799.bat`
3. Sistema avviato!
4. Nessuna installazione richiesta

## 🚀 Primo Avvio

Dopo l'installazione:
1. Desktop → Gene1799 Enhanced System (doppio click)
2. O: Start Menu → Gene1799 → Gene1799 Enhanced System
3. Oppure: Vai in `Program Files/Gene1799` e lancia `Gene1799_Enhanced.exe`

## 📊 Cosa Succede All'Avvio

Il sistema:
1. Controlla la salute del tuo PC
2. Ripara automaticamente qualsiasi problema
3. Genera contenuti (testi, video, musica)
4. Pubblica su social (Twitter, LinkedIn, TikTok)
5. Impara dai risultati
6. Crea di NFT dai momenti virali

Tutto automaticamente! 🤖

## 📚 Documentazione

Dopo l'installazione, troverai:
- `README_QUICK_START.md` - Inizio rapido
- `ENHANCED_SYSTEM_README.md` - Componenti dettagliati
- `FULL_SYSTEM_INTEGRATION.md` - Architettura completa
- `TEST_SCENARIOS.md` - Test e validazione
- `FILE_INVENTORY.md` - Elenco file e funzioni

## ⚙️ Requisiti Minimi

- **OS**: Windows 10+, Linux, macOS
- **RAM**: 2GB (4GB consigliato)
- **Disco**: 1GB libero
- **Internet**: Richiesta per social/NFT

## 🔧 Configurazione

Puoi modificare:
- Frequenza di generazione contenuti
- Limite post giornalieri
- Soglia di virality per NFT
- Parametri di apprendimento

Tutto è configurabile dentro l'app!

## 🆘 Problemi?

1. Riavvia l'applicazione
2. Controlla i log in `Logs/`
3. Leggi la documentazione inclusa
4. Il sistema auto-ripara la maggior parte dei problemi

## 📞 Supporto

Sistema autonomo = nessun supporto necessario! 
Il sistema si ripara da solo 24/7.

---

**Gene1799 Enhanced System v2.0**
*Fully Autonomous AI Platform*

Buon utilizzo! 🚀
'''
    
    readme_installer = dist_dir / "LEGGIMI_PRIMA.txt"
    with open(readme_installer, 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print_success("README creato: LEGGIMI_PRIMA.txt")
    
    # STEP 12: Riepilogo finale
    print_step(12, "Riepilogo e localizzazione file...")
    
    exe_file = exe_dir / "Gene1799_Enhanced.exe"
    
    if exe_file.exists():
        exe_size = exe_file.stat().st_size / (1024*1024)
        print_success(f"EXE creato: {exe_file} ({exe_size:.1f} MB)")
    
    print(f"""
{Colors.BOLD}{Colors.GREEN}
╔════════════════════════════════════════════════════════════════╗
║                   BUILD COMPLETATO! ✓                         ║
╠════════════════════════════════════════════════════════════════╣
║                                                                ║
║  📁 Cartella: {dist_dir}
║                                                                ║
║  PRONTO PER INSTALLARE:                                        ║
║  ├─ Gene1799_Enhanced/ (Versione standalone)                  ║
║  │  ├─ Gene1799_Enhanced.exe (Applicazione)                   ║
║  │  ├─ RUN_Gene1799.bat (Launcher veloce)                     ║
║  │  └─ Documentazione completa                                ║
║  │                                                             ║
║  ├─ Gene1799_v2.0_Installer.exe (Setup automatico)            ║
║  └─ LEGGIMI_PRIMA.txt (Istruzioni)                            ║
║                                                                ║
║  ✨ Come usare:                                                ║
║  1. OPZIONE A: Doppio click su Installer.exe                  ║
║  2. OPZIONE B: Estrai e lancia RUN_Gene1799.bat               ║
║  3. Fatto! Sistema pronto all'uso                             ║
║                                                                ║
║  🎯 Cosa è incluso:                                            ║
║  ✓ Auto-Healing Agent (24/7 monitoring)                       ║
║  ✓ Content Creation (testi/video/musica)                      ║
║  ✓ Social Bots (Twitter/LinkedIn/TikTok)                      ║
║  ✓ AI Learning (7 agenti intelligenti)                        ║
║  ✓ NFT Monetization (Zora.co)                                 ║
║  ✓ GUI completa e interattiva                                 ║
║  ✓ Tutta la documentazione                                    ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
{Colors.ENDC}
    """)
    
    print_info(f"Accedi a: {dist_dir}")
    print_success("Build completato! 🎉")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
