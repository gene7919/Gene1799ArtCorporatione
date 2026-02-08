
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
        print("\n\nSistema chiuso dall'utente.")
        sys.exit(0)
