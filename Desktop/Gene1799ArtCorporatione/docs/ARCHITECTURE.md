# Architettura Gene1799

## Overview del Sistema

Gene1799 Art Corporation è un sistema integrato che combina:

```
┌─────────────────────────────────────────────────────┐
│              FRONTEND WEB (React)                   │
│              localhost:5173                         │
└────────────────────┬────────────────────────────────┘
                     │ HTTP/REST
┌────────────────────▼────────────────────────────────┐
│           BACKEND API (Express.js)                  │
│           localhost:3000                            │
└────────────────────┬────────────────────────────────┘
                     │ Orchestrazione
         ┌───────────┴───────────┐
         │                       │
    ┌────▼─────┐           ┌────▼─────┐
    │ AI Agent │           │ Database  │
    │ (Python) │           │           │
    └──────────┘           └───────────┘

┌─────────────────────────────────────────────────────┐
│         DESKTOP APP (Electron)                      │
│         Interfaccia locale                          │
└─────────────────────────────────────────────────────┘
```

## Componenti Principali

### 1. Frontend Web (React + TypeScript)
- **Teknologi:** React 18, TypeScript, Vite, CSS3
- **Responsabilità:** Interfaccia utente web
- **Porta:** 5173 (development)
- **Comunicazione:** HTTP REST con backend

### 2. Backend API (Express.js)
- **Teknologi:** Node.js, Express.js, REST API
- **Responsabilità:** 
  - Elaborazione richieste HTTP
  - Orchestrazione AI Agent
  - Gestione database
- **Porta:** 3000 (development)
- **Endpoint principali:**
  - GET `/api/health` - Health check
  - GET `/api/info` - Informazioni sistema

### 3. AI Agent System (Python)
- **Teknologi:** Python, Microsoft Agent Framework
- **Responsabilità:**
  - Elaborazione intelligente
  - Machine Learning / NLP
  - Decisioni automatizzate
- **Integrazione:** WebSocket o HTTP con backend

### 4. Desktop App (Electron)
- **Teknologia:** Electron, Node.js
- **Responsabilità:** 
  - Interfaccia desktop nativa
  - Offline-first capabilities
  - Integrazione sistema
- **Piattaforme:** Windows, macOS, Linux

### 5. Shared Libraries
- **Contenuti:**
  - TypeScript types
  - Utility functions
  - Configurazioni comuni
- **Utilizzato da:** Backend, Frontend, Desktop

## Flusso di Comunicazione

```
Frontend Request
      │
      ▼
Backend API → Process Request
      │
      ├─→ Query Database
      │
      ├─→ Call AI Agent (se necessario)
      │             │
      │             ▼
      │        AI Processing
      │             │
      ├─◀───────────┘
      │
      ▼
Response JSON
      │
      ▼
Frontend Display
```

## Stack Tecnologico

| Layer | Tecnologia | Versione |
|-------|-----------|----------|
| Frontend | React | 18.2+ |
| Frontend Build | Vite | 5.0+ |
| Backend | Express.js | 4.18+ |
| Runtime | Node.js | 18+ |
| Desktop | Electron | 27+ |
| AI Framework | Python | 3.9+ |
| Type Safety | TypeScript | 5.2+ |

## Deployment

### Development
```bash
npm install
npm run dev
```

### Production
```bash
npm run build
# Deploy output nelle rispettive /dist folder
```

## Security Considerations

- [ ] Validazione input su backend
- [ ] CORS configurato correttamente
- [ ] Environment variables per secrets
- [ ] HTTPS in produzione
- [ ] Rate limiting su API
- [ ] Autenticazione/Autorizzazione (da implementare)

---

**Versione:** 1.0.0  
**Data:** 2026-02-08
