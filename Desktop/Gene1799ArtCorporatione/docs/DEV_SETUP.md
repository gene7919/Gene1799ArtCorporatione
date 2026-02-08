# Guida Dev Environment

## Prerequisiti Sistema

### Windows
```powershell
# Verifica Node.js
node --version
npm --version

# Verifica Python
python --version

# O installa con Winget (se disponibile)
winget install nodejs.nodejs
winget install python
```

### macOS
```bash
brew install node
brew install python
```

### Linux
```bash
sudo apt update
sudo apt install nodejs npm python3
```

## Setup Iniziale (Step by Step)

### 1. Clone/Download Progetto
```bash
# Se hai git:
git clone <repository-url> gene1799artcorporatione
cd gene1799artcorporatione

# Oppure soltanto apri la cartella in VS Code
```

### 2. Installa Dipendenze Root
```bash
npm install
# Questo installa anche tutte le dipendenze dei workspace
```

### 3. Installa AI Agent Python
```bash
cd ai-agent

# Crea virtual environment
python -m venv venv

# Attiva environment (Windows)
venv\Scripts\activate

# Attiva environment (macOS/Linux)
source venv/bin/activate

# Installa dipendenze
pip install -r requirements.txt

# Torna alla root
cd..
```

### 4. Configura Environment Variables

Crea file `.env` per backend:
```bash
# backend/.env
PORT=3000
NODE_ENV=development
DATABASE_URL=
API_KEY=
```

## Workflow Sviluppo

### Terminale 1 - Backend API
```bash
npm -w backend run dev
# Osserva: 🚀 Backend API running on http://localhost:3000
```

### Terminale 2 - Frontend Web
```bash
npm -w frontend run dev
# Osserva: http://localhost:5173
```

### Terminale 3 - Desktop App (opzionale)
```bash
npm -w desktop run dev
# Apre finestra Electron
```

### Terminale 4 - AI Agent (opzionale)
```bash
cd ai-agent
# Assicurati che venv sia attivato
python main.py
```

## Testing in Development

### Test Endpoint Backend
```bash
# Health check
curl http://localhost:3000/api/health

# Info
curl http://localhost:3000/api/info
```

### Hot Reload
- **Frontend:** ✅ Automatico con Vite
- **Backend:** ✅ Automatico con nodemon
- **Desktop:** Ricarica manuale

## Debugging

### VS Code Extensions Raccomandate
```
- ES7+ React/Redux/React-Native snippets
- TypeScript Vue Plugin
- Pyright (per Python)
- Eslint
- Prettier
```

### Debug Frontend (Chrome DevTools)
1. Apri http://localhost:5173
2. F12 per aprire DevTools
3. Usa Console/Network/React DevTools

### Debug Backend
```bash
# In VS Code: F5 per Debug
# O avvia con:
node --inspect src/index.js
```

## Comandi Utili

```bash
# Tutto
npm run dev
npm run build
npm run test
npm run lint

# Backend
npm -w backend run dev
npm -w backend run test
npm -w backend run lint

# Frontend  
npm -w frontend run dev
npm -w frontend run build
npm -w frontend run type-check
npm -w frontend run lint

# Desktop
npm -w desktop run dev
npm -w desktop run build

# AI Agent
cd ai-agent && python main.py
```

## Troubleshooting

### Issue: Dependencies non installate
```bash
npm clean-install
```

### Issue: Port già in uso
```bash
# Backend (cambia in backend/.env)
# Frontend (cambia con vite --port 5174)
# Desktop (cambia in main.js)
```

### Issue: Python venv non trovato
```bash
cd ai-agent
python -m venv venv
# Riattiva ambiente
```

### Issue: Node modules corrotto
```bash
rm -r node_modules package-lock.json
npm install
```

---

**Data:** 2026-02-08  
**Versione:** 1.0.0
