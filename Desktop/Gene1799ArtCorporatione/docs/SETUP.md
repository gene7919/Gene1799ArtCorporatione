# Documentazione Gene1799

## Struttura del Progetto

```
gene1799artcorporatione/
├── ai-agent/           # Sistema AI (Python)
├── backend/            # API Server (Node.js)
├── frontend/           # Web App (React)
├── desktop/            # Desktop App (Electron)
├── shared/             # Utility condivise
├── docs/               # Documentazione
├── package.json        # Root package config
└── README.md           # Documentazione principale
```

## Setup Iniziale (Guida Completa)

### 1. Prerequisiti

- **Node.js** 18+ (se non installato, scarica da https://nodejs.org)
- **Python** 3.9+ (se non installato, scarica da https://python.org)
- **Git** (opzionale, per versionamento)

### 2. Installazione Dipendenze

```bash
# Dalla cartella root del progetto
npm install

# Questo installa tutte le dipendenze per:
# - Backend
# - Frontend
# - Desktop
```

### 3. Setup AI Agent (Python)

```bash
cd ai-agent
python -m venv venv

# Attivare environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Installare dipendenze
pip install -r requirements.txt
```

## Avvio del Progetto

### Opzione 1: Avvia Tutto

```bash
npm run dev
```

Questo avvia contemporaneamente:
- Backend API (porta 3000)
- Frontend Web (porta 5173)
- Desktop App

### Opzione 2: Avvia Singoli Componenti

**Backend:**
```bash
npm -w backend run dev
```
Accedi su: http://localhost:3000

**Frontend:**
```bash
npm -w frontend run dev
```
Accedi su: http://localhost:5173

**Desktop:**
```bash
npm -w desktop run dev
```

**AI Agent:**
```bash
cd ai-agent
python main.py
```

## Struttura delle Cartelle

### `/backend`
- **src/index.js** - Entry point Express
- **package.json** - Dipendenze Node
- **.env** - Variabili di ambiente

### `/frontend`
- **src/App.tsx** - Componente principale React
- **src/main.tsx** - Entry point Vite
- **index.html** - HTML template
- **tsconfig.json** - Configurazione TypeScript

### `/desktop`
- **main.js** - Entry point Electron
- **preload.js** - Context isolation
- **src/index.html** - Interfaccia desktop
- **package.json** - Dipendenze Electron

### `/ai-agent`
- **main.py** - Entry point Python
- **agent.py** - Logica agent
- **requirements.txt** - Dipendenze Python

### `/shared`
- **index.ts** - Tipi e utility condivisi
- **package.json** - Configurazione npm

## Comandi Disponibili

```bash
# Root directory
npm install              # Installa tutto
npm run dev             # Avvia tutti i componenti
npm run build           # Build di produzione
npm run test            # Esegui test
npm run lint            # Analizza codice

# Per singolo workspace
npm -w [workspace-name] run [script]

# Esempi:
npm -w backend run dev
npm -w frontend run build
npm -w desktop run start
```

## Variabili d'Ambiente

### Backend (`.env`)
```
PORT=3000
NODE_ENV=development
```

### Frontend (`.env`)
```
VITE_API_URL=http://localhost:3000
```

## Build di Produzione

```bash
npm run build

# Output principale in:
# - backend/dist/
# - frontend/dist/
# - desktop/dist/
```

## Troubleshooting

### Problema: `npm command not found`
**Soluzione:** Installa Node.js da https://nodejs.org

### Problema: Port 3000 già in uso
**Soluzione:** 
```bash
# Cambia porta in backend/.env
PORT=3001
```

### Problema: `Python not found`
**Soluzione:** Installa Python da https://python.org

## Supporto e Feedback

Per domande o problemi:
1. Controlla la documentazione nei rispettivi README
2. Verifica i log della console
3. Consulta la guida di troubleshooting

---

**Creato:** 2026-02-08  
**Versione:** 1.0.0  
**Progetto:** Gene1799 Art Corporation
