# Dockerfile per SuiteV17
FROM python:3.11-slim

# Installazione dipendenze di sistema
RUN apt-get update && apt-get install -y \\
    gcc \\
    g++ \\
    curl \\
    wget \\
    git \\
    sqlite3 \\
    nodejs \\
    npm \\
    && rm -rf /var/lib/apt/lists/*

# Directory di lavoro
WORKDIR /app

# Copia requirements e installa Python deps
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia codice
COPY . .

# Crea directory necessarie
RUN mkdir -p data logs backups plugins

# Espone porte
EXPOSE 8080 8083 8765 3007 9090

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \\
    CMD curl -f http://localhost:8083/health || exit 1

# Comando di avvio
CMD ["python", "suitev17_resilient_master.py"]
