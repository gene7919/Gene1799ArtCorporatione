$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " GENE1799 TokenModule Patch - Suite V17 " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# -----------------------------
# CONFIG PRINCIPALE
# -----------------------------
$Root = "C:\SuiteV17"
$ModuleDir = Join-Path $Root "TokenModule"
$ConfigPath = Join-Path $ModuleDir "config.json"
$MonitorPath = Join-Path $ModuleDir "token_monitor.js"
$DataPath = Join-Path $ModuleDir "token_data.json"
$HtmlPath = Join-Path $ModuleDir "token_dashboard.html"
$PackagePath = Join-Path $ModuleDir "package.json"

# Webhook opzionale per SocialHub / Make / n8n
# Lascia vuoto se non vuoi usarlo subito
$WebhookUrl = ""

# Soglia alert prezzo
$PumpThreshold = 0.01

# -----------------------------
# CHECK CARTELLE
# -----------------------------
if (!(Test-Path $Root)) {
    throw "La cartella principale non esiste: $Root"
}

if (!(Test-Path $ModuleDir)) {
    New-Item -ItemType Directory -Path $ModuleDir -Force | Out-Null
    Write-Host "Cartella creata: $ModuleDir" -ForegroundColor Green
}
else {
    Write-Host "Cartella già esistente: $ModuleDir" -ForegroundColor Yellow
}

# -----------------------------
# CREA config.json
# -----------------------------
$configJson = @'
{
  "token": {
    "name": "GENE1799",
    "symbol": "GENE",
    "address": "0x63800f370b04ce132333c05d811663b80cec788e",
    "chain": "base",
    "decimals": 18
  },
  "api": {
    "dex": "https://api.dexscreener.com/latest/dex/tokens/",
    "scan": "https://api.basescan.org/api"
  },
  "alerts": {
    "pumpThreshold": 0.01
  },
  "social": {
    "webhook": ""
  }
}
'@

Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
Write-Host "Creato: config.json" -ForegroundColor Green

# -----------------------------
# CREA token_data.json iniziale
# -----------------------------
$initialData = @'
{
  "token": "GENE1799",
  "symbol": "GENE",
  "chain": "base",
  "address": "0x63800f370b04ce132333c05d811663b80cec788e",
  "price": null,
  "volume24h": null,
  "liquidity": null,
  "fdv": null,
  "txns": null,
  "pairAddress": null,
  "dexId": null,
  "url": null,
  "lastUpdate": null,
  "status": "initialized"
}
'@

Set-Content -Path $DataPath -Value $initialData -Encoding UTF8
Write-Host "Creato: token_data.json" -ForegroundColor Green

# -----------------------------
# CREA token_monitor.js
# -----------------------------
$monitorJs = @'
const fs = require("fs");
const path = require("path");
const axios = require("axios");

const configPath = path.join(__dirname, "config.json");
const outputPath = path.join(__dirname, "token_data.json");
const logPath = path.join(__dirname, "token_monitor.log");

function log(message) {
  const line = `[${new Date().toISOString()}] ${message}`;
  console.log(line);
  try {
    fs.appendFileSync(logPath, line + "\n", "utf8");
  } catch (_) {}
}

function safeReadConfig() {
  return JSON.parse(fs.readFileSync(configPath, "utf-8"));
}

function writeData(data) {
  fs.writeFileSync(outputPath, JSON.stringify(data, null, 2), "utf-8");
}

async function sendWebhook(webhook, payload) {
  if (!webhook || !webhook.trim()) return;
  try {
    await axios.post(webhook, payload, {
      headers: { "Content-Type": "application/json" },
      timeout: 10000
    });
    log("Webhook inviato correttamente");
  } catch (err) {
    log("Errore webhook: " + (err.response?.data ? JSON.stringify(err.response.data) : err.message));
  }
}

async function getTokenData() {
  const config = safeReadConfig();
  const token = config.token.address;
  const api = config.api.dex + token;
  const pumpThreshold = Number(config.alerts?.pumpThreshold || 0.01);
  const webhook = config.social?.webhook || "";

  try {
    const res = await axios.get(api, { timeout: 15000 });

    if (!res.data || !res.data.pairs || res.data.pairs.length === 0) {
      log("Nessuna pool trovata");
      writeData({
        token: config.token.name,
        symbol: config.token.symbol,
        chain: config.token.chain,
        address: config.token.address,
        price: null,
        volume24h: null,
        liquidity: null,
        fdv: null,
        txns: null,
        pairAddress: null,
        dexId: null,
        url: null,
        lastUpdate: new Date().toISOString(),
        status: "no_pool"
      });
      return;
    }

    const pairs = res.data.pairs.filter(p => (p.chainId || "").toLowerCase() === "base");
    const pair = (pairs.length > 0 ? pairs : res.data.pairs)
      .sort((a, b) => (b.liquidity?.usd || 0) - (a.liquidity?.usd || 0))[0];

    const data = {
      token: config.token.name,
      symbol: config.token.symbol,
      chain: config.token.chain,
      address: config.token.address,
      price: pair.priceUsd ?? null,
      volume24h: pair.volume?.h24 ?? null,
      liquidity: pair.liquidity?.usd ?? null,
      fdv: pair.fdv ?? null,
      txns: pair.txns?.h24 ?? null,
      pairAddress: pair.pairAddress ?? null,
      dexId: pair.dexId ?? null,
      url: pair.url ?? null,
      lastUpdate: new Date().toISOString(),
      status: "ok"
    };

    writeData(data);
    log("TOKEN DATA aggiornato: " + JSON.stringify(data));

    const numericPrice = Number(data.price || 0);
    if (numericPrice > pumpThreshold) {
      log("PUMP DETECTED sopra soglia: " + pumpThreshold);

      await sendWebhook(webhook, {
        platform: "telegram",
        title: "GENE1799 Alert",
        source: "TokenModule",
        time: new Date().toISOString(),
        text: `🚀 GENE1799 sopra soglia. Prezzo: $${numericPrice}`
      });
    }
  } catch (err) {
    log("Errore monitor: " + (err.response?.data ? JSON.stringify(err.response.data) : err.message));
    writeData({
      token: "GENE1799",
      symbol: "GENE",
      chain: "base",
      address: "0x63800f370b04ce132333c05d811663b80cec788e",
      price: null,
      volume24h: null,
      liquidity: null,
      fdv: null,
      txns: null,
      pairAddress: null,
      dexId: null,
      url: null,
      lastUpdate: new Date().toISOString(),
      status: "error",
      error: err.message
    });
  }
}

log("Monitor GENE1799 avviato");
getTokenData();
setInterval(getTokenData, 15000);
'@

Set-Content -Path $MonitorPath -Value $monitorJs -Encoding UTF8
Write-Host "Creato: token_monitor.js" -ForegroundColor Green

# -----------------------------
# CREA HTML monitor locale
# -----------------------------
$htmlContent = @'
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <title>GENE1799 Token Monitor</title>
  <style>
    body {
      margin: 0;
      background: #050505;
      color: #d7ff00;
      font-family: Arial, sans-serif;
      padding: 30px;
    }
    .card {
      border: 1px solid #2f3;
      border-radius: 12px;
      padding: 20px;
      max-width: 700px;
      box-shadow: 0 0 18px rgba(120,255,0,0.15);
      background: rgba(0,0,0,0.7);
    }
    h1 {
      margin-top: 0;
    }
    .row {
      margin: 10px 0;
      font-size: 18px;
    }
    .small {
      color: #9acd32;
      font-size: 13px;
      word-break: break-all;
    }
  </style>
</head>
<body>
  <div class="card">
    <h1>GENE1799 Monitor</h1>
    <div class="row" id="status">Stato: caricamento...</div>
    <div class="row" id="price">Prezzo: -</div>
    <div class="row" id="liquidity">Liquidità: -</div>
    <div class="row" id="volume">Volume 24h: -</div>
    <div class="row" id="fdv">FDV: -</div>
    <div class="row" id="txns">TXNS 24h: -</div>
    <div class="row small" id="pair">Pair: -</div>
    <div class="row small" id="url">URL: -</div>
    <div class="row small" id="updated">Ultimo update: -</div>
  </div>

  <script>
    async function loadData() {
      try {
        const res = await fetch("./token_data.json?ts=" + Date.now());
        const data = await res.json();

        document.getElementById("status").textContent = "Stato: " + (data.status ?? "-");
        document.getElementById("price").textContent = "Prezzo: $" + (data.price ?? "-");
        document.getElementById("liquidity").textContent = "Liquidità: $" + (data.liquidity ?? "-");
        document.getElementById("volume").textContent = "Volume 24h: $" + (data.volume24h ?? "-");
        document.getElementById("fdv").textContent = "FDV: $" + (data.fdv ?? "-");
        document.getElementById("txns").textContent = "TXNS 24h: " + JSON.stringify(data.txns ?? "-");
        document.getElementById("pair").textContent = "Pair: " + (data.pairAddress ?? "-");
        document.getElementById("url").textContent = "URL: " + (data.url ?? "-");
        document.getElementById("updated").textContent = "Ultimo update: " + (data.lastUpdate ?? "-");
      } catch (e) {
        document.getElementById("status").textContent = "Stato: errore lettura dati";
      }
    }

    loadData();
    setInterval(loadData, 5000);
  </script>
</body>
</html>
'@

Set-Content -Path $HtmlPath -Value $htmlContent -Encoding UTF8
Write-Host "Creato: token_dashboard.html" -ForegroundColor Green

# -----------------------------
# CREA package.json minimo se assente
# -----------------------------
if (!(Test-Path $PackagePath)) {
    $packageJson = @'
{
  "name": "gene1799-tokenmodule",
  "version": "1.0.0",
  "description": "Token monitor for GENE1799 on Base",
  "main": "token_monitor.js",
  "scripts": {
    "start": "node token_monitor.js"
  }
}
'@
    Set-Content -Path $PackagePath -Value $packageJson -Encoding UTF8
    Write-Host "Creato: package.json" -ForegroundColor Green
}
else {
    Write-Host "package.json già presente" -ForegroundColor Yellow
}

# -----------------------------
# INSTALL NODE MODULES
# -----------------------------
Set-Location $ModuleDir

if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm non trovato nel PATH. Installa Node.js o riapri PowerShell."
}

Write-Host "Installazione dipendenze npm..." -ForegroundColor Cyan
npm install axios | Out-Host

# -----------------------------
# AVVIO PM2
# -----------------------------
if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    Write-Host "PM2 trovato. Configuro il processo..." -ForegroundColor Cyan

    try {
        pm2 delete GENE1799-TOKEN 2>$null | Out-Null
    } catch {}

    pm2 start $MonitorPath --name GENE1799-TOKEN | Out-Host
    pm2 save | Out-Host

    Write-Host "Processo PM2 avviato: GENE1799-TOKEN" -ForegroundColor Green
}
else {
    Write-Host "PM2 non trovato. Avvio fallback con Node normale." -ForegroundColor Yellow
    Start-Process -FilePath "node" -ArgumentList "`"$MonitorPath`"" -WorkingDirectory $ModuleDir
}

# -----------------------------
# ISTRUZIONI FINALI
# -----------------------------
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "File creati:" -ForegroundColor White
Write-Host " - $ConfigPath"
Write-Host " - $MonitorPath"
Write-Host " - $DataPath"
Write-Host " - $HtmlPath"
Write-Host ""
Write-Host "Dashboard locale:" -ForegroundColor White
Write-Host " - Apri: $HtmlPath"
Write-Host ""
Write-Host "Comandi utili:" -ForegroundColor White
Write-Host " - pm2 logs GENE1799-TOKEN"
Write-Host " - pm2 restart GENE1799-TOKEN"
Write-Host " - pm2 stop GENE1799-TOKEN"
Write-Host ""
Write-Host "Nota:" -ForegroundColor Yellow
Write-Host " - Per attivare gli alert webhook, inserisci l'URL nel file config.json -> social.webhook"
Write-Host " - Il monitor aggiorna token_data.json ogni 15 secondi"