import os
import shutil
import subprocess
from datetime import datetime

class SuiteAssembler:
    def __init__(self, agents_dir="./Agents"):
        self.agents_dir = agents_dir
        self.backup_dir = "./Backups/AutoAssembler"
        
        # Crea la cartella di backup se non esiste
        if not os.path.exists(self.backup_dir):
            os.makedirs(self.backup_dir)

    def hot_swap_module(self, module_name, new_code):
        """
        Esegue la sostituzione live del modulo tramite PM2.
        module_name: nome del file (es. 'agent_logic.py')
        new_code: il codice ottimizzato ricevuto dall'Architetto
        """
        file_path = os.path.join(self.agents_dir, module_name)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_path = os.path.join(self.backup_dir, f"{module_name}_{timestamp}.bak")

        try:
            # 1. Backup del modulo esistente (Sicurezza Inviolabile)
            if os.path.exists(file_path):
                shutil.copy2(file_path, backup_path)
                print(f"[ASSEMBLER] Backup creato: {backup_path}")

            # 2. Scrittura del nuovo codice ottimizzato
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(new_code)
            print(f"[ASSEMBLER] Modulo {module_name} aggiornato con successo.")

            # 3. Orchestrazione PM2: Reload senza downtime
            # Usiamo 'reload' invece di 'restart' per mantenere la continuità se supportato
            result = subprocess.run(
                ["pm2", "reload", module_name.replace(".py", "")], 
                capture_output=True, 
                text=True
            )

            if result.returncode == 0:
                print(f"[SUCCESS] PM2 ha riavviato l'agente {module_name} con la nuova logica.")
            else:
                # Se il processo non era attivo su PM2, lo avviamo da zero
                print(f"[INFO] Processo non attivo. Eseguo avvio standard...")
                subprocess.run(["pm2", "start", file_path, "--name", module_name.replace(".py", "")])

        except Exception as e:
            print(f"[ERRORE CRITICO] Fallimento durante l'assemblaggio: {str(e)}")
            self._rollback(file_path, backup_path)

    def _rollback(self, file_path, backup_path):
        """Ripristina la versione precedente in caso di errore di scrittura."""
        if os.path.exists(backup_path):
            shutil.copy2(backup_path, file_path)
            print("[ROLLBACK] Sistema ripristinato alla versione precedente.")