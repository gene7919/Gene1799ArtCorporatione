import time
from suite_watcher import calculate_hash  # Assumendo i nomi file precedenti
from suite_assembler import SuiteAssembler

# Inizializzazione componenti
assembler = SuiteAssembler(agents_dir="./Agents")

def run_integration_test(target_file_1, target_file_2):
    print(f"🚀 Avvio Test Integrazione SUITEV17...")
    
    # 1. Simulazione Watcher: Rilevamento ridondanza
    print(f"🔍 [STEP 1] Analisi file: {target_file_1} e {target_file_2}")
    with open(target_file_1, 'r') as f1, open(target_file_2, 'r') as f2:
        code_a = f1.read()
        code_b = f2.read()
    
    # 2. Chiamata all'Architetto (Ollama)
    # Assicurati che Ollama sia ONLINE come visto nel tuo scan
    print(f"🧠 [STEP 2] Invio all'Architetto per fusione logica...")
    
    # Qui simuliamo la chiamata API a Ollama
    # In produzione useresti: requests.post('http://localhost:11434/api/generate', ...)
    optimized_code = simulate_ollama_architect(code_a, code_b)
    
    # 3. Passaggio all'Assembler per il Hot-Swap
    print(f"🛠️ [STEP 3] Passaggio all'Assembler per aggiornamento live...")
    module_name = "agent_core_optimized.py"
    assembler.hot_swap_module(module_name, optimized_code)
    
    print(f"✅ [FINISH] Ciclo di auto-assemblaggio completato con successo.")

def simulate_ollama_architect(a, b):
    # Simulazione dell'output dell'Architetto per il test
    return f"# SUITEV17 OPTIMIZED MODULE\n# Merged from two sources\n\n{a}\n\n{b}\n# End of Optimized Code"

if __name__ == "__main__":
    # Testiamo con due blueprint che abbiamo visto nel tuo scan
    run_integration_test("./Agents/002_blueprint_of_an_agent.md", "./Agents/002_blueprint_of_an_agent_1.md")