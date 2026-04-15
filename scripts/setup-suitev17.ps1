$ErrorActionPreference = "Stop"

$BasePath   = "C:\SuiteV17"
$ServerFile = Join-Path $BasePath "server.js"
$PkgFile    = Join-Path $BasePath "package.json"
$EnvFile    = Join-Path $BasePath ".env"
$StartFile  = Join-Path $BasePath "start-suitev17.ps1"
$TestFile   = Join-Path $BasePath "test-suitev17.ps1"

New-Item -ItemType Directory -Force -Path $BasePath | Out-Null

@'
{
  "name": "suitev17-social-ingest",
  "version": "1.0.0",
  "main": "server.js",
  "type": "commonjs",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "axios": "^1.8.4",
    "dotenv": "^16.4.7",
    "express": "^4.21.2"
  }
}
'@ | Set-Content -Path $PkgFile -Encoding UTF8

@'
PORT=3007
OLLAMA_URL=http://127.0.0.1:11434/api/generate
OLLAMA_MODEL=llama3.1
API_TOKEN=YOUR_TOKEN
'@ | Set-Content -Path $EnvFile -Encoding UTF8

@'
require("dotenv").config();
const express = require("express");
const axios = require("axios");

const app = express();
app.use(express.json({ limit: "10mb" }));

const PORT = process.env.PORT || 3007;
const API_TOKEN = process.env.API_TOKEN || "YOUR_TOKEN";
const OLLAMA_URL = process.env.OLLAMA_URL || "http://127.0.0.1:11434/api/generate";
const OLLAMA_MODEL = process.env.OLLAMA_MODEL || "llama3.1";

function auth(req, res, next) {
  const hdr = req.headers.authorization || "";
  if (!hdr.startsWith("Bearer ")) return res.status(401).json({ ok: false, error: "Missing bearer token" });
  const token = hdr.slice(7);
  if (token !== API_TOKEN) return res.status(403).json({ ok: false, error: "Invalid token" });
  next();
}

async function askOllama(prompt) {
  const r = await axios.post(OLLAMA_URL, {
    model: OLLAMA_MODEL,
    prompt,
    stream: false
  }, { timeout: 120000 });
  return r.data.response || "";
}

async function enhanceCaption(platform, payload) {
  const baseCaption = payload.caption || "";
  if (!baseCaption) return payload;

  const prompt = [
    "Return only plain text.",
    `Improve this social caption for ${platform}.`,
    "Keep brand tone concise, clear, strong.",
    "Do not add explanations.",
    `Title: ${payload.title || ""}`,
    `Caption: ${baseCaption}`
  ].join("\n");

  const improved = await askOllama(prompt);
  return {
    ...payload,
    caption_original: baseCaption,
    caption: improved.trim() || baseCaption
  };
}

async function handlePlatform(platform, payload) {
  const enhanced = await enhanceCaption(platform, payload);
  return {
    platform,
    accepted: true,
    processed_at: new Date().toISOString(),
    payload: enhanced
  };
}

app.get("/api/health", (req, res) => {
  res.json({
    ok: true,
    service: "SuiteV17 social ingest",
    port: PORT,
    ollama_model: OLLAMA_MODEL
  });
});

app.post("/api/social/ingest", auth, async (req, res) => {
  try {
    const { source, scenario, platform, status, title, caption, media_url, publish_at } = req.body || {};

    if (!platform) return res.status(400).json({ ok: false, error: "platform required" });
    if (!status) return res.status(400).json({ ok: false, error: "status required" });
    if (status !== "approved") return res.status(400).json({ ok: false, error: "content not approved" });

    const payload = { source, scenario, title, caption, media_url, publish_at };

    let result;
    switch ((platform || "").toLowerCase()) {
      case "instagram":
        result = await handlePlatform("instagram", payload);
        break;
      case "tiktok":
        result = await handlePlatform("tiktok", payload);
        break;
      case "youtube":
        result = await handlePlatform("youtube", payload);
        break;
      case "discord":
        result = await handlePlatform("discord", payload);
        break;
      default:
        return res.status(400).json({ ok: false, error: "unsupported platform" });
    }

    return res.json({
      ok: true,
      route: platform,
      scenario,
      result
    });
  } catch (err) {
    return res.status(500).json({
      ok: false,
      error: err.message
    });
  }
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`SuiteV17 backend avviato su http://0.0.0.0:${PORT}`);
});
'@ | Set-Content -Path $ServerFile -Encoding UTF8

@'
Write-Host "=== AVVIO OLLAMA IN NUOVA FINESTRA ===" -ForegroundColor Cyan
Start-Process powershell -ArgumentList '-NoExit','-Command','ollama serve'

Start-Sleep -Seconds 3

Write-Host "=== AVVIO SUITEV17 ===" -ForegroundColor Cyan
Set-Location "C:\SuiteV17"
npm run start
'@ | Set-Content -Path $StartFile -Encoding UTF8

@'
$body = @{
  source = "make"
  scenario = "gen_e1799"
  platform = "discord"
  status = "approved"
  title = "test"
  caption = "ciao"
  media_url = "https://example.com/a.jpg"
  publish_at = (Get-Date).ToString("s")
} | ConvertTo-Json -Depth 5

Invoke-RestMethod `
  -Uri "http://127.0.0.1:3007/api/social/ingest" `
  -Method Post `
  -Headers @{ Authorization = "Bearer YOUR_TOKEN" } `
  -ContentType "application/json" `
  -Body $body
'@ | Set-Content -Path $TestFile -Encoding UTF8

Push-Location $BasePath
npm install
Pop-Location

Write-Host ""
Write-Host "SETUP COMPLETATO." -ForegroundColor Green
Write-Host "1. Modifica C:\SuiteV17\.env e cambia API_TOKEN se vuoi." -ForegroundColor Yellow
Write-Host "2. Avvia: powershell -ExecutionPolicy Bypass -File C:\SuiteV17\start-suitev17.ps1" -ForegroundColor Yellow
Write-Host "3. Testa: powershell -ExecutionPolicy Bypass -File C:\SuiteV17\test-suitev17.ps1" -ForegroundColor Yellow