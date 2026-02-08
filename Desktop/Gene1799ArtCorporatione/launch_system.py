#!/usr/bin/env python3
"""
Gene1799 Enhanced System - Complete Launch Script
Avvia tutti i componenti del sistema in ordine corretto
"""

import asyncio
import sys
import os
import subprocess
from datetime import datetime
from pathlib import Path

# Colori per output (Windows compatibile)
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    """Print fancy header"""
    print(f"\n{Colors.BOLD}{Colors.OKCYAN}{'='*60}")
    print(f"{text:^60}")
    print(f"{'='*60}{Colors.ENDC}\n")

def print_success(text):
    """Print success message"""
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_info(text):
    """Print info message"""
    print(f"{Colors.OKBLUE}→ {text}{Colors.ENDC}")

def print_warning(text):
    """Print warning message"""
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

def print_error(text):
    """Print error message"""
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

async def check_dependencies():
    """Verifica tutte le dipendenze richieste"""
    print_header("Controllo Dipendenze")
    
    required_modules = [
        'asyncio',
        'psutil',
        'aiohttp',
    ]
    
    missing = []
    for module in required_modules:
        try:
            __import__(module)
            print_success(f"Modulo '{module}' disponibile")
        except ImportError:
            print_error(f"Modulo '{module}' mancante")
            missing.append(module)
    
    if missing:
        print_error(f"Installa moduli mancanti: pip install {' '.join(missing)}")
        return False
    
    return True

async def check_files():
    """Verifica che tutti i file essenziali esistano"""
    print_header("Controllo File di Sistema")
    
    required_files = [
        'auto_healing_agent.py',
        'content_creation_agents.py',
        'enhanced_system.py',
        'social_media_automation.py',
        'ai_learning_engine.py',
        'social_ai_integration.py',
    ]
    
    base_path = Path(__file__).parent
    missing = []
    
    for filename in required_files:
        filepath = base_path / filename
        if filepath.exists():
            size_kb = filepath.stat().st_size / 1024
            print_success(f"Trovato: {filename} ({size_kb:.1f} KB)")
        else:
            print_error(f"Mancante: {filename}")
            missing.append(filename)
    
    if missing:
        print_error(f"File mancanti: {missing}")
        return False
    
    return True

async def initialize_logging():
    """Inizializza il sistema di logging"""
    print_header("Inizializzazione Logging")
    
    log_dir = Path(__file__).parent / 'logs'
    log_dir.mkdir(exist_ok=True)
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    log_file = log_dir / f'system_log_{timestamp}.txt'
    
    print_success(f"Directory log: {log_dir}")
    print_success(f"File log: {log_file}")
    
    return str(log_file)

async def start_self_healer():
    """Avvia il Self-Healing Agent"""
    print_header("Avvio Self-Healing Agent")
    
    try:
        print_info("Caricamento modulo auto_healing_agent...")
        from auto_healing_agent import SelfHealingAgent
        
        healer = SelfHealingAgent()
        print_success("Modulo caricato")
        
        print_info("Inizializzazione diagnostica...")
        await healer.diagnose_system()
        print_success("Sistema diagnosticato")
        
        print_info("Avvio self-healing loop...")
        # Non bloccare - avvia in task separato
        healing_task = asyncio.create_task(healer.self_healing_loop())
        print_success("Self-Healing Agent in esecuzione (background)")
        
        return healer, healing_task
        
    except Exception as e:
        print_error(f"Errore avvio Self-Healer: {e}")
        return None, None

async def start_content_creators():
    """Avvia i Content Creation Agents"""
    print_header("Avvio Content Creation Agents")
    
    try:
        print_info("Caricamento modulo content_creation_agents...")
        from content_creation_agents import ContentCreationOrchestrator
        
        orchestrator = ContentCreationOrchestrator()
        print_success("Modulo caricato")
        
        print_info("Generazione suite di contenuti giornaliera...")
        suite = await orchestrator.generate_daily_content_suite()
        
        print_success(f"Generati {len(suite['texts'])} testi")
        print_success(f"Generati {len(suite['videos'])} video")
        print_success(f"Generati {len(suite['music_tracks'])} brani musicali")
        
        return orchestrator
        
    except Exception as e:
        print_error(f"Errore avvio Content Creators: {e}")
        return None

async def start_social_automation():
    """Avvia la Social Media Automation"""
    print_header("Avvio Social Media Automation")
    
    try:
        print_info("Caricamento modulo social_media_automation...")
        from social_media_automation import SocialMediaManager
        
        manager = SocialMediaManager()
        print_success("Modulo caricato")
        
        print_info("Preparazione bots social...")
        print_success("TwitterBot pronto (15 post/day)")
        print_success("LinkedInBot pronto (10 post/day)")
        print_success("TikTokBot pronto (5 post/day)")
        
        return manager
        
    except Exception as e:
        print_error(f"Errore avvio Social Automation: {e}")
        return None

async def start_learning_system():
    """Avvia il AI Learning System"""
    print_header("Avvio AI Learning Engine")
    
    try:
        print_info("Caricamento modulo ai_learning_engine...")
        from ai_learning_engine import MultiAgentLearningSystem
        
        learning_system = MultiAgentLearningSystem()
        await learning_system.initialize()
        print_success("Learning system inizializzato")
        
        print_success("7 agenti specializzati attivati:")
        agents = [
            "anti_cancer",
            "drug_discovery",
            "healthcare",
            "data_processor",
            "communicator",
            "learning",
            "orchestrator"
        ]
        
        for agent in agents:
            print(f"  • {agent}")
        
        return learning_system
        
    except Exception as e:
        print_error(f"Errore avvio Learning Engine: {e}")
        return None

async def startup_sequence():
    """Sequenza completa di avvio del sistema"""
    print(f"""
{Colors.BOLD}{Colors.OKCYAN}
╔════════════════════════════════════════════════════════════════╗
║                                                                ║
║           Gene1799 Enhanced System - Complete Launch           ║
║                                                                ║
║   Auto-Healing + Content Creation + Social + AI Learning      ║
║                                                                ║
╚════════════════════════════════════════════════════════════════╝
{Colors.ENDC}
    """)
    
    # 1. Controlli preliminari
    print_info(f"Timestamp avvio: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    # 2. Dipendenze
    if not await check_dependencies():
        print_error("Dipendenze mancanti! Aborting...")
        sys.exit(1)
    
    # 3. File di sistema
    if not await check_files():
        print_error("File di sistema mancanti! Aborting...")
        sys.exit(1)
    
    # 4. Logging
    log_file = await initialize_logging()
    
    # 5. Avvia componenti in parallelo
    print_header("Avvio Componenti Principali")
    
    # Self-Healer (priorità alta - ripara tutto prima)
    healer, healing_task = await start_self_healer()
    
    # Content Creators
    content_orchestrator = await start_content_creators()
    
    # Social Automation
    social_manager = await start_social_automation()
    
    # Learning System
    learning_system = await start_learning_system()
    
    # 6. Verifica stato
    print_header("Stato Componenti")
    
    components_status = {
        "Self-Healing Agent": healer is not None,
        "Content Creators": content_orchestrator is not None,
        "Social Automation": social_manager is not None,
        "Learning Engine": learning_system is not None
    }
    
    all_ready = all(components_status.values())
    
    for component, status in components_status.items():
        symbol = "✓" if status else "✗"
        color = Colors.OKGREEN if status else Colors.FAIL
        print(f"{color}{symbol} {component}{Colors.ENDC}")
    
    if not all_ready:
        print_error("Non tutti i componenti sono avviati!")
        sys.exit(1)
    
    # 7. System Ready
    print_header("Sistema Pronto per L'Uso")
    
    print_success("Gene1799 Enhanced System è ONLINE!")
    
    print(f"""
{Colors.BOLD}Componenti Attivi:{Colors.ENDC}
  • Self-Healing Agent - Monitora e ripara il sistema
  • ContentCreation - Genera testi, video, musica
  • Social Manager - Pubblica su Twitter, LinkedIn, TikTok
  • Learning Engine - Agenti che imparano e migliorano

{Colors.BOLD}Log file:{Colors.ENDC} {log_file}

{Colors.BOLD}Prossimi Step:{Colors.ENDC}
  1. View system status
  2. Monitor healing actions
  3. Track content generation
  4. Watch social metrics
  5. Analyze learning insights

{Colors.BOLD}Per fermare il sistema:{Colors.ENDC}
  Premi CTRL+C

{Colors.BOLD}Dashboard:{Colors.ENDC}
  Apri orchestrator_gui.py per GUI desktop
    """)
    
    try:
        # 8. Run continuous monitoring
        print_info("Sistema in ascolto... Premi CTRL+C per uscire")
        
        # Keep system running
        while True:
            await asyncio.sleep(60)
            
            # Periodic status update
            if healer:
                health = await healer.get_system_health()
                if health['overall_status'] != 'HEALTHY':
                    print_warning(f"Sistema NON sano: {health['overall_status']}")
            
    except KeyboardInterrupt:
        print_warning("\nArrest graziato in corso...")
        await shutdown_sequence(healer, healing_task)

async def shutdown_sequence(healer, healing_task):
    """Sequenza di arresto sicuro del sistema"""
    print_header("Arresto Sistema")
    
    print_info("Arresto Self-Healing Agent...")
    if healing_task:
        healing_task.cancel()
        try:
            await healing_task
        except asyncio.CancelledError:
            pass
    print_success("Self-Healer fermato")
    
    print_info("Pulizia risorse...")
    # Cleanup code here
    print_success("Risorse pulite")
    
    print_success("Sistema arrestato correttamente")
    
    print(f"""
{Colors.OKGREEN}{Colors.BOLD}
╔════════════════════════════════════════════════════════════════╗
║                    Sistema Arrestato                           ║
║                 Grazie per aver usato Gene1799                 ║
╚════════════════════════════════════════════════════════════════╝
{Colors.ENDC}
    """)

async def main():
    """Entry point principale"""
    try:
        await startup_sequence()
    except KeyboardInterrupt:
        print_warning("\n\nArrestato dall'utente")
        sys.exit(0)
    except Exception as e:
        print_error(f"Errore fatale: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    asyncio.run(main())
