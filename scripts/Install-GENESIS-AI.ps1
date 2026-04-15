Write-Host ""
Write-Host "GENESIS AI INSTALLER" -ForegroundColor Cyan
Write-Host ""

cd C:\SuiteV17

# verifica ollama
Write-Host "Controllo Ollama..."
ollama list

# modello principale
Write-Host "Test LLM..."
ollama run llama3.1 "rispondi solo OK"

# embedding
Write-Host "Test Embedding..."
ollama run nomic-embed-text "test"

# installa dipendenze python
Write-Host "Installazione moduli Python..."

pip install requests
pip install fastapi
pip install uvicorn
pip install sentence-transformers

# avvio RAG
Write-Host "Avvio AI RAG..."

pm2 start gene_rag_core.py --name gene_rag_core
pm2 start gene_rag_bridge.py --name gene_rag_bridge

# salva configurazione
pm2 save

Write-Host ""
Write-Host "GENESIS AI INSTALLATA" -ForegroundColor Green
Write-Host ""