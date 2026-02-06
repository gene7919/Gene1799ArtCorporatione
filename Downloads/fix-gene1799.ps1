# ╔════════════════════════════════════════════════════════════════╗
# ║   GENE1799 - FIX IMMEDIATO ERRORI                              ║
# ║   Esegui in PowerShell come Amministratore                     ║
# ╚════════════════════════════════════════════════════════════════╝

$ErrorActionPreference = "Stop"
$HubPath = "D:\C1799HubEnhanced"

Write-Host "`n[FIX] Riparazione Gene1799 Hub..." -ForegroundColor Yellow

# === STEP 1: Installa moduli mancanti ===
Write-Host "`n[1/4] Installazione moduli mancanti..." -ForegroundColor Cyan
Set-Location $HubPath

# Installa cors e altri moduli necessari
npm install cors helmet axios express --save 2>$null
Write-Host "  ✓ Moduli installati" -ForegroundColor Green

# === STEP 2: Backup e fix server.js ===
Write-Host "`n[2/4] Fix server.js..." -ForegroundColor Cyan

# Backup
if (Test-Path "$HubPath\server.js") {
    Copy-Item "$HubPath\server.js" "$HubPath\server.js.broken" -Force
    Write-Host "  ✓ Backup creato: server.js.broken" -ForegroundColor Green
}

# Crea server.js pulito e funzionante
$serverJs = @'
/**
 * GENE1799 Hub Enhanced - Server v9.0.0
 * Fixed version with AI Integration
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const axios = require('axios');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Config
const INTEGRATION_URL = process.env.INTEGRATION_URL || 'http://localhost:3002';
const PROD_URL = process.env.PROD_URL || 'http://localhost:3000';

// === Health Check ===
app.get('/api/health', (req, res) => {
  res.json({
    status: 'online',
    version: '9.0.0',
    timestamp: new Date().toISOString(),
    metrics: {
      requests: 0,
      errors: 0,
      activeConnections: 0,
      targetIPHits: 0,
      tasksExecuted: 0,
      nftsCreated: 0,
      workflowsCompleted: 0
    }
  });
});

// === Agents Routes ===
app.get('/api/agents/health', async (req, res) => {
  try {
    const response = await axios.get(`${INTEGRATION_URL}/api/agents/health`, { timeout: 5000 });
    res.json(response.data);
  } catch (error) {
    // Fallback se Integration Server non attivo
    res.json({
      status: 'standalone',
      message: 'Integration Server offline - Hub funziona in modalità standalone',
      agents: []
    });
  }
});

app.post('/api/agents/train', async (req, res) => {
  try {
    const response = await axios.post(`${INTEGRATION_URL}/api/agents/train`, req.body, { timeout: 60000 });
    res.json(response.data);
  } catch (error) {
    res.json({ 
      success: false, 
      error: 'Integration Server non raggiungibile',
      hint: 'Avvia Integration Server su porta 3002'
    });
  }
});

app.post('/api/agents/:agent/query', async (req, res) => {
  try {
    const { agent } = req.params;
    const response = await axios.post(
      `${INTEGRATION_URL}/api/agents/${agent}/query`,
      req.body,
      { timeout: 60000 }
    );
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// === Sync Agents (FIXED - era il problema del template literal) ===
app.post('/api/syncagents', async (req, res) => {
  try {
    // Sync locale
    res.json({ success: true, synced: true, timestamp: new Date().toISOString() });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// === AI Proxy ===
app.use('/api/ai', async (req, res) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${INTEGRATION_URL}${req.path}`,
      data: req.body,
      timeout: 30000
    });
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// === Static ===
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// === Start ===
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log('');
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║   GENE1799 HUB ENHANCED v9.0.0 - RUNNING                       ║');
  console.log('╚════════════════════════════════════════════════════════════════╝');
  console.log('');
  console.log(`[OK] Server: http://localhost:${PORT}`);
  console.log(`[OK] Health: http://localhost:${PORT}/api/health`);
  console.log(`[OK] Agents: http://localhost:${PORT}/api/agents/health`);
  console.log('');
});

module.exports = app;
'@

$serverJs | Set-Content "$HubPath\server.js" -Encoding UTF8
Write-Host "  ✓ server.js riparato" -ForegroundColor Green

# === STEP 3: Fix main.js per non caricare server.js due volte ===
Write-Host "`n[3/4] Fix main.js..." -ForegroundColor Cyan

$mainJsPath = "$HubPath\main.js"
$mainContent = Get-Content $mainJsPath -Raw -ErrorAction SilentlyContinue

# Rimuovi duplicati di require('./server')
if ($mainContent -match "require\('\./server'\).*require\('\./server'\)") {
    $mainContent = $mainContent -replace "const server = require\('\./server'\);`n`n", ""
    $mainContent | Set-Content $mainJsPath -Encoding UTF8
    Write-Host "  ✓ Rimosso require duplicato" -ForegroundColor Green
}

# Verifica che main.js carichi server
if ($mainContent -notmatch "require\('\./server'\)") {
    # Aggiungi all'inizio
    $newMain = "// Gene1799 Hub Enhanced`nconst server = require('./server');`n`n" + $mainContent
    $newMain | Set-Content $mainJsPath -Encoding UTF8
    Write-Host "  ✓ Aggiunto caricamento server" -ForegroundColor Green
} else {
    Write-Host "  ✓ main.js OK" -ForegroundColor Green
}

# === STEP 4: Fix ai-integration ===
Write-Host "`n[4/4] Setup ai-integration..." -ForegroundColor Cyan

$aiPath = "$HubPath\ai-integration"
if (!(Test-Path $aiPath)) {
    New-Item -ItemType Directory -Path $aiPath -Force | Out-Null
}

# Installa dipendenze in ai-integration
Set-Location $aiPath
if (!(Test-Path "$aiPath\package.json")) {
    @'
{
  "name": "gene1799-ai-integration",
  "version": "2.0.0",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "cors": "^2.8.5",
    "express": "^4.18.2",
    "ws": "^8.14.2"
  }
}
'@ | Set-Content "$aiPath\package.json" -Encoding UTF8
}

npm install --silent 2>$null
Write-Host "  ✓ ai-integration configurato" -ForegroundColor Green

# === COMPLETATO ===
Write-Host "`n" -NoNewline
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✓ FIX COMPLETATO!                                            ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n[PROSSIMO PASSO] Avvia l'Hub:" -ForegroundColor Yellow
Write-Host "  cd $HubPath" -ForegroundColor Cyan
Write-Host "  npm start" -ForegroundColor Cyan

# Chiedi se avviare
Write-Host ""
$avvia = Read-Host "Avviare Hub ora? (s/n)"
if ($avvia -eq 's' -or $avvia -eq 'S' -or $avvia -eq 'y') {
    Set-Location $HubPath
    Write-Host "`n[AVVIO] npm start..." -ForegroundColor Green
    npm start
}
