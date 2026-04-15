$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " GENE1799 TokenModule Patch V2 - Suite V17 " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$ModuleDir = Join-Path $Root "TokenModule"
$ServerPath = Join-Path $ModuleDir "server.js"
$DashboardPath = Join-Path $ModuleDir "dashboard_matrix.html"
$ConfigPath = Join-Path $ModuleDir "config.json"
$PackagePath = Join-Path $ModuleDir "package.json"

if (!(Test-Path $ModuleDir)) {
    throw "TokenModule non trovato. Prima esegui la patch base."
}

# =========================
# Aggiorna config.json
# =========================
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
    "pumpThreshold": 0.01,
    "liquidityMinWarning": 300
  },
  "social": {
    "webhook": "",
    "enabled": false
  },
  "telegram": {
    "botToken": "",
    "chatId": "",
    "enabled": false
  },
  "server": {
    "port": 3018
  }
}
'@
Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
Write-Host "config.json aggiornato" -ForegroundColor Green

# =========================
# Crea server.js
# =========================
$serverJs = @'
const fs = require("fs");
const path = require("path");
const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

const baseDir = __dirname;
const configPath = path.join(baseDir, "config.json");
const dataPath = path.join(baseDir, "token_data.json");
const logPath = path.join(baseDir, "token_monitor.log");
const dashboardPath = path.join(baseDir, "dashboard_matrix.html");

function loadConfig() {
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function safeReadJson(filePath, fallback = {}) {
  try {
    return JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch {
    return fallback;
  }
}

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    service: "GENE1799 TokenModule",
    time: new Date().toISOString()
  });
});

app.get("/api/token", (req, res) => {
  const data = safeReadJson(dataPath, { status: "missing" });
  res.json(data);
});

app.get("/api/config", (req, res) => {
  const cfg = loadConfig();
  res.json({
    token: cfg.token,
    alerts: cfg.alerts,
    server: cfg.server,
    social: {
      enabled: cfg.social?.enabled || false
    },
    telegram: {
      enabled: cfg.telegram?.enabled || false,
      chatIdConfigured: !!cfg.telegram?.chatId
    }
  });
});

app.get("/api/logs", (req, res) => {
  try {
    const txt = fs.readFileSync(logPath, "utf8");
    const lines = txt.split(/\r?\n/).filter(Boolean).slice(-100);
    res.json({ lines });
  } catch {
    res.json({ lines: [] });
  }
});

app.get("/", (req, res) => {
  res.sendFile(dashboardPath);
});

const port = Number(loadConfig().server?.port || 3018);
app.listen(port, () => {
  console.log(`[SERVER] GENE1799 dashboard online su http://localhost:${port}`);
});
'@
Set-Content -Path $ServerPath -Value $serverJs -Encoding UTF8
Write-Host "Creato: server.js" -ForegroundColor Green

# =========================
# Aggiorna token_monitor.js
# =========================
$monitorPath = Join-Path $ModuleDir "token_monitor.js"
$monitorJs = @'
const fs = require("fs");
const path = require("path");
const axios = require("axios");

const configPath = path.join(__dirname, "config.json");
const outputPath = path.join(__dirname, "token_data.json");
const logPath = path.join(__dirname, "token_monitor.log");

let lastPumpAlertAt = 0;
let lastLiquidityAlertAt = 0;

function log(message) {
  const line = `[${new Date().toISOString()}] ${message}`;
  console.log(line);
  try {
    fs.appendFileSync(logPath, line + "\n", "utf8");
  } catch (_) {}
}

function readConfig() {
  return JSON.parse(fs.readFileSync(configPath, "utf8"));
}

function writeData(data) {
  fs.writeFileSync(outputPath, JSON.stringify(data, null, 2), "utf8");
}

async function sendWebhook(webhook, payload) {
  if (!webhook || !webhook.trim()) return false;
  try {
    await axios.post(webhook, payload, {
      headers: { "Content-Type": "application/json" },
      timeout: 10000
    });
    log("Webhook inviato");
    return true;
  } catch (err) {
    log("Errore webhook: " + (err.response?.data ? JSON.stringify(err.response.data) : err.message));
    return false;
  }
}

async function sendTelegram(botToken, chatId, text) {
  if (!botToken || !chatId) return false;
  try {
    const url = `https://api.telegram.org/bot${botToken}/sendMessage`;
    await axios.post(url, {
      chat_id: chatId,
      text
    }, { timeout: 10000 });
    log("Messaggio Telegram inviato");
    return true;
  } catch (err) {
    log("Errore Telegram: " + (err.response?.data ? JSON.stringify(err.response.data) : err.message));
    return false;
  }
}

function canSend(lastTime, cooldownMs) {
  return Date.now() - lastTime > cooldownMs;
}

async function getTokenData() {
  const config = readConfig();
  const token = config.token.address;
  const api = config.api.dex + token;

  try {
    const res = await axios.get(api, { timeout: 15000 });

    if (!res.data || !res.data.pairs || res.data.pairs.length === 0) {
      log("Nessuna pool trovata");
      writeData({
        token: config.token.name,
        symbol: config.token.symbol,
        chain: config.token.chain,
        address: config.token.address,
        status: "no_pool",
        lastUpdate: new Date().toISOString()
      });
      return;
    }

    const pairs = res.data.pairs.filter(p => (p.chainId || "").toLowerCase() === "base");
    const pair = (pairs.length ? pairs : res.data.pairs)
      .sort((a, b) => (b.liquidity?.usd || 0) - (a.liquidity?.usd || 0))[0];

    const data = {
      token: config.token.name,
      symbol: config.token.symbol,
      chain: config.token.chain,
      address: config.token.address,
      price: Number(pair.priceUsd ?? 0),
      volume24h: Number(pair.volume?.h24 ?? 0),
      liquidity: Number(pair.liquidity?.usd ?? 0),
      fdv: Number(pair.fdv ?? 0),
      txns: pair.txns?.h24 ?? {},
      pairAddress: pair.pairAddress ?? null,
      dexId: pair.dexId ?? null,
      pairUrl: pair.url ?? null,
      baseToken: pair.baseToken ?? null,
      quoteToken: pair.quoteToken ?? null,
      priceChange: pair.priceChange ?? {},
      lastUpdate: new Date().toISOString(),
      status: "ok"
    };

    writeData(data);
    log("TOKEN DATA aggiornato: " + JSON.stringify(data));

    const pumpThreshold = Number(config.alerts?.pumpThreshold || 0.01);
    const liquidityMinWarning = Number(config.alerts?.liquidityMinWarning || 300);

    const socialEnabled = !!config.social?.enabled;
    const webhook = config.social?.webhook || "";

    const telegramEnabled = !!config.telegram?.enabled;
    const botToken = config.telegram?.botToken || "";
    const chatId = config.telegram?.chatId || "";

    if (data.price > pumpThreshold && canSend(lastPumpAlertAt, 30 * 60 * 1000)) {
      const text = `🚀 GENE1799 PUMP ALERT
Prezzo: $${data.price}
Liquidità: $${data.liquidity}
Volume24h: $${data.volume24h}
DEX: ${data.dexId}
URL: ${data.pairUrl || "-"}`;

      log("Pump alert trigger");

      if (socialEnabled) {
        await sendWebhook(webhook, {
          platform: "telegram",
          title: "GENE1799 Pump Alert",
          source: "TokenModule",
          time: new Date().toISOString(),
          text
        });
      }

      if (telegramEnabled) {
        await sendTelegram(botToken, chatId, text);
      }

      lastPumpAlertAt = Date.now();
    }

    if (data.liquidity < liquidityMinWarning && canSend(lastLiquidityAlertAt, 30 * 60 * 1000)) {
      const text = `⚠️ GENE1799 LIQUIDITY WARNING
Liquidità: $${data.liquidity}
Prezzo: $${data.price}
Volume24h: $${data.volume24h}
DEX: ${data.dexId}
URL: ${data.pairUrl || "-"}`;

      log("Liquidity alert trigger");

      if (socialEnabled) {
        await sendWebhook(webhook, {
          platform: "telegram",
          title: "GENE1799 Liquidity Warning",
          source: "TokenModule",
          time: new Date().toISOString(),
          text
        });
      }

      if (telegramEnabled) {
        await sendTelegram(botToken, chatId, text);
      }

      lastLiquidityAlertAt = Date.now();
    }

  } catch (err) {
    log("Errore monitor: " + (err.response?.data ? JSON.stringify(err.response.data) : err.message));
    writeData({
      token: "GENE1799",
      symbol: "GENE",
      chain: "base",
      address: "0x63800f370b04ce132333c05d811663b80cec788e",
      status: "error",
      error: err.message,
      lastUpdate: new Date().toISOString()
    });
  }
}

log("Monitor GENE1799 V2 avviato");
getTokenData();
setInterval(getTokenData, 15000);
'@
Set-Content -Path $monitorPath -Value $monitorJs -Encoding UTF8
Write-Host "Aggiornato: token_monitor.js" -ForegroundColor Green

# =========================
# Crea dashboard Matrix
# =========================
$dashboardHtml = @'
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>GENE1799 Matrix Dashboard</title>
<style>
  body {
    margin: 0;
    background: #030607;
    color: #ccff00;
    font-family: Consolas, monospace;
    overflow-x: hidden;
  }
  .wrap {
    max-width: 1200px;
    margin: 0 auto;
    padding: 24px;
  }
  .title {
    font-size: 34px;
    margin-bottom: 8px;
    text-shadow: 0 0 10px rgba(204,255,0,0.5);
  }
  .sub {
    color: #7d9f00;
    margin-bottom: 20px;
  }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
    gap: 16px;
  }
  .card {
    background: rgba(0,0,0,0.45);
    border: 1px solid #4f6;
    border-radius: 18px;
    padding: 18px;
    box-shadow: 0 0 18px rgba(120,255,0,0.1);
  }
  .label {
    color: #7d9f00;
    font-size: 13px;
    margin-bottom: 8px;
  }
  .value {
    font-size: 28px;
    word-break: break-word;
  }
  .logs {
    margin-top: 20px;
    background: rgba(0,0,0,0.45);
    border: 1px solid #4f6;
    border-radius: 18px;
    padding: 18px;
    height: 280px;
    overflow: auto;
    white-space: pre-wrap;
    font-size: 13px;
  }
  a { color: #ccff00; }
</style>
</head>
<body>
<div class="wrap">
  <div class="title">GENE1799 // MATRIX DASHBOARD</div>
  <div class="sub">Suite V17 live monitor</div>

  <div class="grid">
    <div class="card"><div class="label">STATUS</div><div class="value" id="status">...</div></div>
    <div class="card"><div class="label">PRICE</div><div class="value" id="price">...</div></div>
    <div class="card"><div class="label">LIQUIDITY</div><div class="value" id="liquidity">...</div></div>
    <div class="card"><div class="label">VOLUME 24H</div><div class="value" id="volume">...</div></div>
    <div class="card"><div class="label">FDV</div><div class="value" id="fdv">...</div></div>
    <div class="card"><div class="label">TXNS</div><div class="value" id="txns">...</div></div>
    <div class="card"><div class="label">DEX</div><div class="value" id="dex">...</div></div>
    <div class="card"><div class="label">PAIR</div><div class="value" id="pair" style="font-size:14px">...</div></div>
  </div>

  <div class="logs" id="logs">Caricamento log...</div>
</div>

<script>
async function loadToken() {
  const res = await fetch('/api/token?ts=' + Date.now());
  const data = await res.json();

  document.getElementById('status').textContent = data.status ?? '-';
  document.getElementById('price').textContent = '$' + (data.price ?? '-');
  document.getElementById('liquidity').textContent = '$' + (data.liquidity ?? '-');
  document.getElementById('volume').textContent = '$' + (data.volume24h ?? '-');
  document.getElementById('fdv').textContent = '$' + (data.fdv ?? '-');
  document.getElementById('txns').textContent = JSON.stringify(data.txns ?? {});
  document.getElementById('dex').textContent = data.dexId ?? '-';
  document.getElementById('pair').innerHTML = data.pairUrl
    ? `<a href="${data.pairUrl}" target="_blank">${data.pairAddress ?? data.pairUrl}</a>`
    : (data.pairAddress ?? '-');
}

async function loadLogs() {
  const res = await fetch('/api/logs?ts=' + Date.now());
  const data = await res.json();
  document.getElementById('logs').textContent = (data.lines || []).join('\n');
}

async function boot() {
  await loadToken();
  await loadLogs();
}

boot();
setInterval(loadToken, 5000);
setInterval(loadLogs, 8000);
</script>
</body>
</html>
'@
Set-Content -Path $DashboardPath -Value $dashboardHtml -Encoding UTF8
Write-Host "Creato: dashboard_matrix.html" -ForegroundColor Green

# =========================
# Aggiorna package.json
# =========================
$packageJson = @'
{
  "name": "gene1799-tokenmodule",
  "version": "2.0.0",
  "description": "GENE1799 token monitor + local dashboard server",
  "main": "server.js",
  "scripts": {
    "start": "node token_monitor.js",
    "server": "node server.js"
  }
}
'@
Set-Content -Path $PackagePath -Value $packageJson -Encoding UTF8
Write-Host "package.json aggiornato" -ForegroundColor Green

# =========================
# Installa dipendenze
# =========================
Set-Location $ModuleDir

if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm non trovato nel PATH."
}

Write-Host "Installazione dipendenze..." -ForegroundColor Cyan
npm install axios express cors | Out-Host

# =========================
# PM2 monitor
# =========================
if (Get-Command pm2 -ErrorAction SilentlyContinue) {
    try { pm2 delete GENE1799-TOKEN 2>$null | Out-Null } catch {}
    try { pm2 delete GENE1799-DASH 2>$null | Out-Null } catch {}

    pm2 start .\token_monitor.js --name GENE1799-TOKEN | Out-Host
    pm2 start .\server.js --name GENE1799-DASH | Out-Host
    pm2 save | Out-Host
    Write-Host "PM2 aggiornato: GENE1799-TOKEN + GENE1799-DASH" -ForegroundColor Green
} else {
    Write-Host "PM2 non trovato, avvio manuale necessario" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PATCH V2 COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Apri la dashboard qui:" -ForegroundColor White
Write-Host "http://localhost:3018"
Write-Host ""
Write-Host "Comandi utili:" -ForegroundColor White
Write-Host "pm2 status"
Write-Host "pm2 logs GENE1799-TOKEN"
Write-Host "pm2 logs GENE1799-DASH"
Write-Host ""
Write-Host "Per Telegram:" -ForegroundColor Yellow
Write-Host "modifica C:\SuiteV17\TokenModule\config.json"
Write-Host "telegram.enabled = true"
Write-Host "telegram.botToken = TUO_BOT_TOKEN"
Write-Host "telegram.chatId = TUO_CHAT_ID"
Write-Host ""
Write-Host "Per SocialHub / Make / n8n:" -ForegroundColor Yellow
Write-Host "social.enabled = true"
Write-Host "social.webhook = TUO_WEBHOOK"