$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // AIHUB OLLAMA PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$AIHub = Join-Path $Root "AIHub"
$Skills = Join-Path $AIHub "skills"
$Logs = Join-Path $AIHub "logs"

New-Item -ItemType Directory -Force -Path $AIHub | Out-Null
New-Item -ItemType Directory -Force -Path $Skills | Out-Null
New-Item -ItemType Directory -Force -Path $Logs | Out-Null

$ConfigPath = Join-Path $AIHub "config.json"
$ServerPath = Join-Path $AIHub "ollama_router.js"
$PackagePath = Join-Path $AIHub "package.json"
$LaunchPath = Join-Path $AIHub "Launch-AIHub.ps1"
$DesktopLaunch = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 AIHub.bat"

$configJson = @'
{
  "ollama": {
    "baseUrl": "http://127.0.0.1:11434",
    "models": {
      "general": "qwen3:8b",
      "fallback": "qwen3:4b",
      "embedding": "embeddinggemma:latest",
      "codingOptional": "qwen3-coder:30b"
    },
    "keepAlive": "15m",
    "think": false
  },
  "server": {
    "port": 3020
  },
  "suite": {
    "tokenDataPath": "C:\\SuiteV17\\TokenModule\\token_data.json",
    "tokenLogPath": "C:\\SuiteV17\\TokenModule\\token_monitor.log",
    "socialConfigPath": "C:\\SuiteV17\\SocialHubV1\\config\\appsettings.json",
    "browserHealthUrl": "http://127.0.0.1:8093/health",
    "tokenDashHealthUrl": "http://127.0.0.1:3018/health"
  }
}
'@

$packageJson = @'
{
  "name": "suitev17-aihub",
  "version": "1.0.0",
  "description": "AIHub locale basato su Ollama per Suite V17",
  "main": "ollama_router.js",
  "scripts": {
    "start": "node ollama_router.js"
  },
  "dependencies": {
    "axios": "^1.8.4",
    "cors": "^2.8.5",
    "express": "^4.21.2"
  }
}
'@

$serverJs = @'
const fs = require("fs");
const path = require("path");
const express = require("express");
const cors = require("cors");
const axios = require("axios");

const app = express();
app.use(cors());
app.use(express.json({ limit: "2mb" }));

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"));
const PORT = Number(config.server?.port || 3020);
const OLLAMA = config.ollama?.baseUrl || "http://127.0.0.1:11434";
const KEEP_ALIVE = config.ollama?.keepAlive || "15m";
const THINK = !!config.ollama?.think;

function readJsonSafe(p, fallback = {}) {
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return fallback;
  }
}

function readTextSafe(p, fallback = "") {
  try {
    return fs.readFileSync(p, "utf8");
  } catch {
    return fallback;
  }
}

function tailLines(text, count = 80) {
  return String(text || "").split(/\r?\n/).filter(Boolean).slice(-count);
}

async function probe(url, timeout = 2500) {
  try {
    const res = await axios.get(url, { timeout });
    return { ok: true, status: res.status, data: res.data };
  } catch (err) {
    return { ok: false, error: err.message };
  }
}

async function ollamaChat(model, messages, format = null) {
  const body = {
    model,
    messages,
    stream: false,
    think: THINK,
    keep_alive: KEEP_ALIVE
  };

  if (format) body.format = format;

  const res = await axios.post(`${OLLAMA}/api/chat`, body, { timeout: 120000 });
  return res.data;
}

async function ollamaEmbed(model, input) {
  const res = await axios.post(`${OLLAMA}/api/embed`, {
    model,
    input,
    keep_alive: KEEP_ALIVE
  }, { timeout: 120000 });

  return res.data;
}

function buildSnapshot() {
  const tokenData = readJsonSafe(config.suite.tokenDataPath, {});
  const socialCfg = readJsonSafe(config.suite.socialConfigPath, {});
  const tokenLog = tailLines(readTextSafe(config.suite.tokenLogPath, ""), 60);

  return {
    tokenData,
    social: {
      app: socialCfg.app || {},
      publish: socialCfg.publish || {}
    },
    tokenLog
  };
}

app.get("/health", async (req, res) => {
  const browser = await probe(config.suite.browserHealthUrl);
  const tokenDash = await probe(config.suite.tokenDashHealthUrl);
  const ollama = await probe(`${OLLAMA}/api/tags`);

  res.json({
    ok: true,
    service: "SuiteV17 AIHub",
    now: new Date().toISOString(),
    ollama,
    browser,
    tokenDash
  });
});

app.get("/api/models", async (req, res) => {
  try {
    const tags = await axios.get(`${OLLAMA}/api/tags`, { timeout: 10000 });
    res.json(tags.data);
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get("/api/snapshot", async (req, res) => {
  const browser = await probe(config.suite.browserHealthUrl);
  const tokenDash = await probe(config.suite.tokenDashHealthUrl);

  res.json({
    ok: true,
    now: new Date().toISOString(),
    snapshot: buildSnapshot(),
    browser,
    tokenDash
  });
});

app.post("/api/analyze/token", async (req, res) => {
  try {
    const snap = buildSnapshot();
    const model = req.body.model || config.ollama.models.general;

    const schema = {
      type: "object",
      properties: {
        summary: { type: "string" },
        riskLevel: { type: "string" },
        action: { type: "string" },
        anomalies: {
          type: "array",
          items: { type: "string" }
        }
      },
      required: ["summary", "riskLevel", "action", "anomalies"]
    };

    const messages = [
      {
        role: "system",
        content: "Sei l'analista operativo di Suite V17. Rispondi in italiano, in modo sintetico e concreto."
      },
      {
        role: "user",
        content: `Analizza questi dati token e restituisci solo JSON valido secondo lo schema.\n\n${JSON.stringify(snap.tokenData, null, 2)}`
      }
    ];

    const out = await ollamaChat(model, messages, schema);
    res.json({ ok: true, model, result: out.message });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/analyze/logs", async (req, res) => {
  try {
    const snap = buildSnapshot();
    const model = req.body.model || config.ollama.models.general;

    const schema = {
      type: "object",
      properties: {
        diagnosis: { type: "string" },
        severity: { type: "string" },
        likelyCause: { type: "string" },
        nextSteps: {
          type: "array",
          items: { type: "string" }
        }
      },
      required: ["diagnosis", "severity", "likelyCause", "nextSteps"]
    };

    const messages = [
      {
        role: "system",
        content: "Sei un tecnico di Suite V17. Analizza i log e proponi solo fix pratici."
      },
      {
        role: "user",
        content: `Analizza questi log del TokenModule e restituisci solo JSON valido.\n\n${snap.tokenLog.join("\n")}`
      }
    ];

    const out = await ollamaChat(model, messages, schema);
    res.json({ ok: true, model, result: out.message });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/generate/social", async (req, res) => {
  try {
    const snap = buildSnapshot();
    const model = req.body.model || config.ollama.models.general;

    const schema = {
      type: "object",
      properties: {
        title: { type: "string" },
        telegram: { type: "string" },
        x: { type: "string" },
        instagram: { type: "string" },
        hashtags: {
          type: "array",
          items: { type: "string" }
        }
      },
      required: ["title", "telegram", "x", "instagram", "hashtags"]
    };

    const messages = [
      {
        role: "system",
        content: "Sei il generatore contenuti di SocialHubV1. Produci contenuti puliti, brevi e pronti all'uso."
      },
      {
        role: "user",
        content: `Genera contenuti social dai dati attuali di GENE1799. Restituisci solo JSON valido.\n\nTOKEN:\n${JSON.stringify(snap.tokenData, null, 2)}\n\nSOCIAL CONFIG:\n${JSON.stringify(snap.social, null, 2)}`
      }
    ];

    const out = await ollamaChat(model, messages, schema);
    res.json({ ok: true, model, result: out.message });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/embed/text", async (req, res) => {
  try {
    const model = req.body.model || config.ollama.models.embedding;
    const input = req.body.input || "";

    if (!input) {
      return res.status(400).json({ ok: false, error: "input mancante" });
    }

    const out = await ollamaEmbed(model, input);
    res.json({ ok: true, model, result: out });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`[AIHub] online su http://127.0.0.1:${PORT}`);
});
'@

$launchPs1 = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\AIHub"
Start-Process node -ArgumentList ".\ollama_router.js" -WorkingDirectory "C:\SuiteV17\AIHub"
'@

$desktopBat = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\AIHub\Launch-AIHub.ps1"
'@

Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
Set-Content -Path $PackagePath -Value $packageJson -Encoding UTF8
Set-Content -Path $ServerPath -Value $serverJs -Encoding UTF8
Set-Content -Path $LaunchPath -Value $launchPs1 -Encoding UTF8
Set-Content -Path $DesktopLaunch -Value $desktopBat -Encoding ASCII

Write-Host "File AIHub creati." -ForegroundColor Green

Set-Location $AIHub
npm install | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " AIHUB OLLAMA PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Cartella: C:\SuiteV17\AIHub"
Write-Host "Launcher Desktop: $DesktopLaunch"
Write-Host ""
Write-Host "Modelli consigliati da pullare:"
Write-Host "  ollama pull qwen3:8b"
Write-Host "  ollama pull qwen3:4b"
Write-Host "  ollama pull embeddinggemma:latest"
Write-Host ""
Write-Host "Avvio AIHub:"
Write-Host '  powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\AIHub\Launch-AIHub.ps1"'
Write-Host ""
Write-Host "Test health:"
Write-Host "  http://127.0.0.1:3020/health"