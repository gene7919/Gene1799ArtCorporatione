# ╔════════════════════════════════════════════════════════════════╗
# ║   GENE1799 AI SYSTEM - INSTALLAZIONE E INTEGRAZIONE           ║
# ║   Esegui come Amministratore per migliori risultati           ║
# ╚════════════════════════════════════════════════════════════════╝

$ErrorActionPreference = "Continue"
$HubPath = "D:\C1799HubEnhanced"
$AISystemPath = "$HubPath\ai-integration"

Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   GENE1799 AI SYSTEM - INSTALLAZIONE AUTOMATICA               ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

# === STEP 1: Verifica prerequisiti ===
Write-Host "[1/6] Verifica prerequisiti..." -ForegroundColor Cyan

# Check Node.js
$nodeVersion = node --version 2>$null
if ($nodeVersion) {
    Write-Host "  ✓ Node.js: $nodeVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Node.js non trovato! Installa da https://nodejs.org" -ForegroundColor Red
    exit 1
}

# Check Ollama
$ollamaRunning = $false
try {
    $ollamaTest = Invoke-WebRequest -Uri "http://localhost:11434/api/tags" -TimeoutSec 3 -UseBasicParsing -ErrorAction SilentlyContinue
    if ($ollamaTest.StatusCode -eq 200) {
        $ollamaRunning = $true
        Write-Host "  ✓ Ollama: Online" -ForegroundColor Green
    }
} catch {
    Write-Host "  ⚠ Ollama: Non in esecuzione (opzionale)" -ForegroundColor Yellow
    Write-Host "    Per AI locale gratuita: ollama serve" -ForegroundColor Gray
}

# === STEP 2: Crea struttura cartelle ===
Write-Host "`n[2/6] Creazione struttura..." -ForegroundColor Cyan

$folders = @(
    "$AISystemPath",
    "$AISystemPath\config",
    "$AISystemPath\providers", 
    "$AISystemPath\agents",
    "$AISystemPath\core",
    "$AISystemPath\dashboard",
    "$AISystemPath\scripts",
    "$AISystemPath\data",
    "$AISystemPath\data\agents",
    "$AISystemPath\data\learning"
)

foreach ($folder in $folders) {
    if (!(Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}
Write-Host "  ✓ Struttura cartelle creata" -ForegroundColor Green

# === STEP 3: Crea package.json ===
Write-Host "`n[3/6] Creazione package.json..." -ForegroundColor Cyan

$packageJson = @'
{
  "name": "gene1799-ai-system",
  "version": "2.0.0",
  "description": "Gene1799 Self-Learning AI Agents with Multi-AI Support",
  "main": "core/IntegrationServer.js",
  "scripts": {
    "start": "node core/IntegrationServer.js",
    "dev": "nodemon core/IntegrationServer.js",
    "monitor": "node scripts/monitor.js",
    "test": "node scripts/test-agents.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "ws": "^8.14.2"
  }
}
'@
$packageJson | Set-Content "$AISystemPath\package.json" -Encoding UTF8
Write-Host "  ✓ package.json creato" -ForegroundColor Green

# === STEP 4: Installa dipendenze ===
Write-Host "`n[4/6] Installazione dipendenze npm..." -ForegroundColor Cyan

Push-Location $AISystemPath
npm install --silent 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Dipendenze installate" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Alcune dipendenze potrebbero mancare" -ForegroundColor Yellow
}
Pop-Location

# === STEP 5: Fix server.js dell'Hub ===
Write-Host "`n[5/6] Integrazione con Hub esistente..." -ForegroundColor Cyan

$serverJsPath = "$HubPath\server.js"
$serverContent = Get-Content $serverJsPath -Raw -ErrorAction SilentlyContinue

# Crea nuovo server.js pulito se ha errori
$newServerJs = @'
/**
 * GENE1799 Hub Enhanced - Server
 * Con integrazione AI System
 */

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const axios = require('axios');
const path = require('path');

const app = express();

// Middleware
app.use(cors());
app.use(helmet({ contentSecurityPolicy: false }));
app.use(express.json());
app.use(express.static('public'));

// === AI Integration Proxy ===
const AI_INTEGRATION_URL = process.env.AI_URL || 'http://localhost:3002';

// Proxy tutte le richieste /api/ai verso Integration Server
app.use('/api/ai', async (req, res) => {
  try {
    const targetPath = req.path || '';
    const response = await axios({
      method: req.method,
      url: `${AI_INTEGRATION_URL}${targetPath}`,
      data: req.body,
      headers: { 'Content-Type': 'application/json' },
      timeout: 30000
    });
    res.json(response.data);
  } catch (error) {
    console.error('[AI Proxy] Error:', error.message);
    res.status(error.response?.status || 500).json({ 
      error: error.message,
      hint: 'Verifica che Integration Server sia attivo su porta 3002'
    });
  }
});

// === Routes Agenti (proxy diretto) ===
app.get('/api/agents/health', async (req, res) => {
  try {
    const response = await axios.get(`${AI_INTEGRATION_URL}/api/agents/health`, { timeout: 5000 });
    res.json(response.data);
  } catch (error) {
    res.status(503).json({ status: 'offline', error: 'Integration Server non raggiungibile' });
  }
});

app.post('/api/agents/train', async (req, res) => {
  try {
    const response = await axios.post(`${AI_INTEGRATION_URL}/api/agents/train`, req.body, { timeout: 60000 });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.post('/api/agents/:agent/query', async (req, res) => {
  try {
    const { agent } = req.params;
    const response = await axios.post(
      `${AI_INTEGRATION_URL}/api/agents/${agent}/query`, 
      req.body,
      { timeout: 60000 }
    );
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// === Health Check Generale ===
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    service: 'Gene1799 Hub Enhanced',
    version: '9.0.0',
    timestamp: new Date().toISOString(),
    aiIntegration: AI_INTEGRATION_URL,
    metrics: {
      requests: 0,
      errors: 0,
      activeConnections: 0
    }
  });
});

// === Static Files ===
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// === Error Handler ===
app.use((err, req, res, next) => {
  console.error('[Error]', err.message);
  res.status(500).json({ error: err.message });
});

// === Start Server ===
const PORT = process.env.PORT || 3000;
const server = app.listen(PORT, () => {
  console.log(`\n╔════════════════════════════════════════════════════════════════╗`);
  console.log(`║   GENE1799 HUB ENHANCED v9.0.0                                 ║`);
  console.log(`║   Port: ${PORT} | AI Integration: ${AI_INTEGRATION_URL}            ║`);
  console.log(`╚════════════════════════════════════════════════════════════════╝\n`);
  console.log(`[Hub] API: http://localhost:${PORT}/api`);
  console.log(`[Hub] AI Proxy: http://localhost:${PORT}/api/ai/*`);
  console.log(`[Hub] Agents: http://localhost:${PORT}/api/agents/*\n`);
});

module.exports = server;
'@

# Backup e sostituisci
if (Test-Path $serverJsPath) {
    Copy-Item $serverJsPath "$HubPath\server.js.backup" -Force
    Write-Host "  ✓ Backup server.js creato" -ForegroundColor Green
}

$newServerJs | Set-Content $serverJsPath -Encoding UTF8
Write-Host "  ✓ server.js aggiornato con AI integration" -ForegroundColor Green

# === STEP 6: Crea script di avvio ===
Write-Host "`n[6/6] Creazione scripts di avvio..." -ForegroundColor Cyan

# Script avvio completo
$startScript = @'
# GENE1799 - Avvio Sistema Completo
Write-Host "`n[GENE1799] Avvio sistema completo...`n" -ForegroundColor Green

# 1. Avvia Integration Server (AI)
Write-Host "[1/2] Avvio AI Integration Server (porta 3002)..." -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd D:\C1799HubEnhanced\ai-integration; npm start" -WindowStyle Normal

Start-Sleep 3

# 2. Avvia Hub (Electron)
Write-Host "[2/2] Avvio Hub Enhanced (porta 3000)..." -ForegroundColor Cyan
Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd D:\C1799HubEnhanced; npm start" -WindowStyle Normal

Write-Host "`n[OK] Sistema avviato!" -ForegroundColor Green
Write-Host "  - Hub: http://localhost:3000" -ForegroundColor White
Write-Host "  - AI Dashboard: http://localhost:3002" -ForegroundColor White
Write-Host "  - AI API: http://localhost:3002/api/*" -ForegroundColor White
'@
$startScript | Set-Content "$HubPath\start-full-system.ps1" -Encoding UTF8

# Script solo AI
$startAI = @'
# Avvia solo AI Integration Server
cd D:\C1799HubEnhanced\ai-integration
npm start
'@
$startAI | Set-Content "$AISystemPath\start.ps1" -Encoding UTF8

Write-Host "  ✓ Scripts di avvio creati" -ForegroundColor Green

# === COMPLETATO ===
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✓ INSTALLAZIONE COMPLETATA!                                  ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n[PROSSIMI PASSI]" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Estrai i file AI dal ZIP scaricato:" -ForegroundColor White
Write-Host "   Copia il contenuto di gene1799-ai-system.zip in:" -ForegroundColor Gray
Write-Host "   D:\C1799HubEnhanced\ai-integration\" -ForegroundColor Cyan
Write-Host ""
Write-Host "2. Avvia il sistema completo:" -ForegroundColor White
Write-Host "   .\start-full-system.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "3. Oppure avvia separatamente:" -ForegroundColor White
Write-Host "   # Terminale 1 - AI Server:" -ForegroundColor Gray
Write-Host "   cd D:\C1799HubEnhanced\ai-integration; npm start" -ForegroundColor Cyan
Write-Host ""
Write-Host "   # Terminale 2 - Hub:" -ForegroundColor Gray
Write-Host "   cd D:\C1799HubEnhanced; npm start" -ForegroundColor Cyan
Write-Host ""
Write-Host "[ENDPOINTS]" -ForegroundColor Yellow
Write-Host "  Hub:          http://localhost:3000" -ForegroundColor White
Write-Host "  AI Dashboard: http://localhost:3002" -ForegroundColor White
Write-Host "  AI Status:    http://localhost:3002/api/status" -ForegroundColor White
Write-Host "  Agents:       http://localhost:3000/api/agents/*" -ForegroundColor White
Write-Host ""

# Chiedi se avviare
$avvia = Read-Host "Vuoi avviare il sistema ora? (s/n)"
if ($avvia -eq 's' -or $avvia -eq 'S') {
    Write-Host "`nAvvio in corso..." -ForegroundColor Green
    & "$HubPath\start-full-system.ps1"
}
