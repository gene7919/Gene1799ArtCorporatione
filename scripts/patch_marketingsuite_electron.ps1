$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // MARKETING SUITE PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$Suite = Join-Path $Root "MarketingSuite"
$Agents = Join-Path $Suite "agents"
$Output = Join-Path $Suite "output"
$OutText = Join-Path $Output "text"
$OutMusic = Join-Path $Output "music"
$OutVideo = Join-Path $Output "video"
$OutCampaigns = Join-Path $Output "campaigns"
$Logs = Join-Path $Suite "logs"

$PackagePath = Join-Path $Suite "package.json"
$MainPath = Join-Path $Suite "main.js"
$PreloadPath = Join-Path $Suite "preload.js"
$IndexPath = Join-Path $Suite "index.html"
$ServerPath = Join-Path $Suite "marketing_server.js"
$ConfigPath = Join-Path $Suite "config.json"
$LaunchPs1 = Join-Path $Suite "Launch-MarketingSuite.ps1"
$LaunchBat = Join-Path $Suite "Launch-MarketingSuite.bat"
$DesktopBat = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 Marketing Suite.bat"

foreach ($dir in @($Suite,$Agents,$Output,$OutText,$OutMusic,$OutVideo,$OutCampaigns,$Logs)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$configJson = @'
{
  "server": {
    "port": 3022
  },
  "aihub": {
    "baseUrl": "http://127.0.0.1:3020"
  },
  "models": {
    "text": "qwen3:4b",
    "fallback": "qwen3:8b"
  },
  "paths": {
    "text": "C:\\SuiteV17\\MarketingSuite\\output\\text",
    "music": "C:\\SuiteV17\\MarketingSuite\\output\\music",
    "video": "C:\\SuiteV17\\MarketingSuite\\output\\video",
    "campaigns": "C:\\SuiteV17\\MarketingSuite\\output\\campaigns",
    "logs": "C:\\SuiteV17\\MarketingSuite\\logs"
  }
}
'@

$packageJson = @'
{
  "name": "suitev17-marketing-suite",
  "version": "1.0.0",
  "description": "Suite marketing separata per testi, musica e video",
  "main": "main.js",
  "scripts": {
    "start": "electron .",
    "server": "node marketing_server.js"
  },
  "devDependencies": {
    "electron": "^41.0.3"
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
app.use(express.json({ limit: "4mb" }));

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"));
const PORT = Number(config.server?.port || 3022);
const AIHUB = config.aihub?.baseUrl || "http://127.0.0.1:3020";

function ensureDir(p) {
  try { fs.mkdirSync(p, { recursive: true }); } catch {}
}

function stamp() {
  const d = new Date();
  const pad = n => String(n).padStart(2,"0");
  return `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

function writeJson(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2), "utf8");
}

function readJsonSafe(file, fallback = {}) {
  try { return JSON.parse(fs.readFileSync(file, "utf8")); } catch { return fallback; }
}

function tail(file, count = 80) {
  try {
    return fs.readFileSync(file, "utf8").split(/\\r?\\n/).filter(Boolean).slice(-count);
  } catch {
    return [];
  }
}

function logLine(text) {
  const file = path.join(config.paths.logs, "marketing_suite.log");
  fs.appendFileSync(file, `[${new Date().toISOString()}] ${text}\\n`, "utf8");
}

function saveCampaign(job) {
  const file = path.join(config.paths.campaigns, `${job.id}.json`);
  writeJson(file, job);
}

function listCampaigns() {
  ensureDir(config.paths.campaigns);
  return fs.readdirSync(config.paths.campaigns)
    .filter(f => f.endsWith(".json"))
    .map(f => readJsonSafe(path.join(config.paths.campaigns, f), null))
    .filter(Boolean)
    .sort((a,b) => String(b.createdAt).localeCompare(String(a.createdAt)));
}

app.get("/health", async (req, res) => {
  let aihub = { ok: false };
  try {
    const out = await axios.get(`${AIHUB}/health`, { timeout: 4000 });
    aihub = { ok: true, status: out.status };
  } catch (err) {
    aihub = { ok: false, error: err.message };
  }

  res.json({
    ok: true,
    service: "MarketingSuite",
    now: new Date().toISOString(),
    aihub
  });
});

app.get("/api/campaigns", (req, res) => {
  res.json({ ok: true, campaigns: listCampaigns() });
});

app.get("/api/logs", (req, res) => {
  const file = path.join(config.paths.logs, "marketing_suite.log");
  res.json({ ok: true, lines: tail(file, 120) });
});

app.post("/api/agent/text", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const model = req.body.model || config.models.text;
    if (!prompt) return res.status(400).json({ ok: false, error: "prompt mancante" });

    const out = await axios.post(`${AIHUB}/api/generate/social`, { model, prompt_override: prompt }, { timeout: 120000 });
    const file = path.join(config.paths.text, `text_${stamp()}.json`);
    writeJson(file, out.data);
    logLine(`TEXT agent -> ${file}`);
    res.json({ ok: true, outputFile: file, result: out.data });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/agent/music", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const mood = String(req.body.mood || "cinematic");
    const duration = Number(req.body.duration || 8);
    if (!prompt) return res.status(400).json({ ok: false, error: "prompt mancante" });

    const job = {
      id: `music_${stamp()}`,
      type: "music_agent",
      createdAt: new Date().toISOString(),
      prompt,
      mood,
      duration,
      status: "prepared",
      recommendedPrompt: `${mood}, ${prompt}, marketing campaign soundtrack, branded identity`,
      note: "Pronto per MusicGen/AudioCraft GPU"
    };

    const file = path.join(config.paths.music, `${job.id}.json`);
    writeJson(file, job);
    logLine(`MUSIC agent -> ${file}`);
    res.json({ ok: true, outputFile: file, result: job });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/agent/video", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const duration = Number(req.body.duration || 4);
    const format = String(req.body.format || "promo");
    if (!prompt) return res.status(400).json({ ok: false, error: "prompt mancante" });

    const job = {
      id: `video_${stamp()}`,
      type: "video_agent",
      createdAt: new Date().toISOString(),
      prompt,
      duration,
      format,
      status: "prepared",
      recommendedPrompt: `${format}, ${prompt}, coherent branded motion, marketing video`,
      note: "Pronto per LTX-Video GPU"
    };

    const file = path.join(config.paths.video, `${job.id}.json`);
    writeJson(file, job);
    logLine(`VIDEO agent -> ${file}`);
    res.json({ ok: true, outputFile: file, result: job });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/orchestrator/campaign", async (req, res) => {
  try {
    const concept = String(req.body.concept || "").trim();
    const model = req.body.model || config.models.text;
    if (!concept) return res.status(400).json({ ok: false, error: "concept mancante" });

    const id = `campaign_${stamp()}`;

    const textOut = await axios.post(`${AIHUB}/api/generate/social`, {
      model,
      prompt_override: `Crea concept marketing per musica, testo e video partendo da: ${concept}`
    }, { timeout: 120000 });

    const campaign = {
      id,
      type: "campaign_orchestrator",
      createdAt: new Date().toISOString(),
      concept,
      textPlan: textOut.data,
      musicPlan: {
        prompt: `${concept}, branded soundtrack, emotional identity, marketing campaign`,
        status: "prepared"
      },
      videoPlan: {
        prompt: `${concept}, promo clip, visual brand identity, cinematic campaign`,
        status: "prepared"
      }
    };

    saveCampaign(campaign);
    logLine(`CAMPAIGN orchestrator -> ${id}`);
    res.json({ ok: true, campaign });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.listen(PORT, () => {
  ensureDir(config.paths.text);
  ensureDir(config.paths.music);
  ensureDir(config.paths.video);
  ensureDir(config.paths.campaigns);
  ensureDir(config.paths.logs);
  console.log(`[MarketingSuite] online su http://127.0.0.1:${PORT}`);
});
'@

$mainJs = @'
const { app, BrowserWindow, shell } = require("electron");
const path = require("path");
const fs = require("fs");

function ensureDir(dir) {
  try { fs.mkdirSync(dir, { recursive: true }); } catch {}
}

app.commandLine.appendSwitch("disable-gpu");
app.commandLine.appendSwitch("disable-software-rasterizer");

function createWindow() {
  const userDataPath = path.join(__dirname, "UserData");
  ensureDir(userDataPath);

  const win = new BrowserWindow({
    width: 1580,
    height: 960,
    minWidth: 1180,
    minHeight: 760,
    backgroundColor: "#090a12",
    title: "Suite V17 // Marketing Suite",
    autoHideMenuBar: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  win.loadFile(path.join(__dirname, "index.html"));

  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });
}

app.whenReady().then(() => {
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
'@

$preloadJs = @'
const { contextBridge, shell } = require("electron");
const http = require("http");
const https = require("https");
const { exec } = require("child_process");

function getJson(url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith("https") ? https : http;
    const req = lib.get(url, (res) => {
      let data = "";
      res.on("data", c => data += c);
      res.on("end", () => {
        try { resolve(JSON.parse(data)); }
        catch (err) { reject(err); }
      });
    });
    req.on("error", reject);
  });
}

function postJson(url, body) {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const payload = JSON.stringify(body);
    const lib = u.protocol === "https:" ? https : http;

    const req = lib.request({
      hostname: u.hostname,
      port: u.port || (u.protocol === "https:" ? 443 : 80),
      path: u.pathname + (u.search || ""),
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(payload)
      }
    }, (res) => {
      let data = "";
      res.on("data", c => data += c);
      res.on("end", () => {
        try { resolve(JSON.parse(data)); }
        catch (err) { reject(err); }
      });
    });

    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

function startMarketingServer() {
  return new Promise((resolve) => {
    const cmd = `Start-Process node -ArgumentList '.\\marketing_server.js' -WorkingDirectory 'C:\\SuiteV17\\MarketingSuite'`;
    exec(`powershell -NoProfile -ExecutionPolicy Bypass -Command "${cmd}"`, { windowsHide: true }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        stdout: stdout || "",
        stderr: stderr || "",
        error: error ? error.message : ""
      });
    });
  });
}

function startAIHub() {
  return new Promise((resolve) => {
    const cmd = `Start-Process node -ArgumentList '.\\ollama_router.js' -WorkingDirectory 'C:\\SuiteV17\\AIHub'`;
    exec(`powershell -NoProfile -ExecutionPolicy Bypass -Command "${cmd}"`, { windowsHide: true }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        stdout: stdout || "",
        stderr: stderr || "",
        error: error ? error.message : ""
      });
    });
  });
}

contextBridge.exposeInMainWorld("marketingSuite", {
  health: () => getJson("http://127.0.0.1:3022/health"),
  campaigns: () => getJson("http://127.0.0.1:3022/api/campaigns"),
  logs: () => getJson("http://127.0.0.1:3022/api/logs"),
  textAgent: (prompt, model) => postJson("http://127.0.0.1:3022/api/agent/text", { prompt, model }),
  musicAgent: (prompt, mood, duration) => postJson("http://127.0.0.1:3022/api/agent/music", { prompt, mood, duration }),
  videoAgent: (prompt, duration, format) => postJson("http://127.0.0.1:3022/api/agent/video", { prompt, duration, format }),
  campaignOrchestrator: (concept, model) => postJson("http://127.0.0.1:3022/api/orchestrator/campaign", { concept, model }),
  startMarketingServer,
  startAIHub,
  openPath: (target) => shell.openPath(target),
  openExternal: (url) => shell.openExternal(url)
});
'@

$indexHtml = @'
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>Suite V17 // Marketing Suite</title>
<style>
:root{
  --bg:#0a0b13;
  --panel:rgba(16,18,30,.95);
  --line:#ff7a59;
  --text:#ffe7df;
  --muted:#d0a59a;
}
*{box-sizing:border-box}
body{
  margin:0;
  background:linear-gradient(180deg,#06070d 0%,#0d101a 100%);
  color:var(--text);
  font-family:Consolas,"Courier New",monospace;
}
.wrap{max-width:1700px;margin:0 auto;padding:18px}
.topbar,.panel{
  background:var(--panel);
  border:1px solid rgba(255,122,89,.2);
  border-radius:18px;
  box-shadow:0 0 24px rgba(255,122,89,.08);
}
.topbar{
  padding:16px 18px;
  margin-bottom:16px;
  display:flex;justify-content:space-between;align-items:center;gap:16px
}
.title{font-size:28px;font-weight:700}
.sub{font-size:13px;color:var(--muted);margin-top:4px}
.badge{
  padding:8px 12px;border-radius:999px;
  background:rgba(255,122,89,.08);
  border:1px solid rgba(255,122,89,.2);
  font-size:12px
}
.grid{display:grid;grid-template-columns:360px 1fr 420px;gap:16px}
.panel{padding:16px}
.stack,.form-grid,.btn-grid{display:grid;gap:12px}
textarea,input,select{
  width:100%;
  border-radius:12px;
  border:1px solid rgba(255,122,89,.18);
  background:rgba(0,0,0,.25);
  color:var(--text);
  padding:10px 12px;
  font-family:inherit;
}
textarea{min-height:120px;resize:vertical}
button{
  width:100%;padding:11px 12px;border-radius:12px;
  border:1px solid rgba(255,122,89,.22);
  background:rgba(255,122,89,.08);
  color:var(--text);cursor:pointer;font-family:inherit
}
button:hover{background:rgba(255,122,89,.14)}
.box{
  min-height:240px;max-height:480px;overflow:auto;white-space:pre-wrap;
  font-size:12px;line-height:1.45;background:rgba(0,0,0,.28);
  border:1px solid rgba(255,122,89,.12);border-radius:14px;padding:12px
}
.small{font-size:12px;color:var(--muted)}
@media (max-width:1280px){.grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="wrap">
  <div class="topbar">
    <div>
      <div class="title">SUITE V17 // MARKETING SUITE</div>
      <div class="sub">Agenti separati per testi, musica, video e campagne</div>
    </div>
    <div class="badge" id="healthBadge">BOOT...</div>
  </div>

  <div class="grid">
    <div class="stack">
      <div class="panel">
        <h2>Quick Actions</h2>
        <div class="btn-grid">
          <button id="startAIHubBtn">Avvia AIHub</button>
          <button id="startServerBtn">Avvia Marketing Server</button>
          <button id="refreshBtn">Aggiorna stato</button>
          <button id="openSuiteBtn">Apri cartella MarketingSuite</button>
          <button id="openTextBtn">Apri output text</button>
          <button id="openMusicBtn">Apri output music</button>
          <button id="openVideoBtn">Apri output video</button>
          <button id="openCampaignsBtn">Apri campaigns</button>
        </div>
      </div>

      <div class="panel">
        <h2>Stato</h2>
        <div class="small" id="statusBox">Caricamento...</div>
      </div>
    </div>

    <div class="stack">
      <div class="panel">
        <h2>Campaign Orchestrator</h2>
        <div class="form-grid">
          <select id="campaignModel">
            <option value="qwen3:4b">qwen3:4b</option>
            <option value="qwen3:8b">qwen3:8b</option>
          </select>
          <textarea id="campaignConcept" placeholder="Descrivi la campagna marketing..."></textarea>
          <button id="runCampaignBtn">Genera campagna coordinata</button>
        </div>
      </div>

      <div class="panel">
        <h2>Text Agent</h2>
        <div class="form-grid">
          <select id="textModel">
            <option value="qwen3:4b">qwen3:4b</option>
            <option value="qwen3:8b">qwen3:8b</option>
          </select>
          <textarea id="textPrompt" placeholder="Prompt testo marketing..."></textarea>
          <button id="runTextBtn">Genera testi</button>
        </div>
      </div>

      <div class="panel">
        <h2>Music Agent</h2>
        <div class="form-grid">
          <input id="musicPrompt" placeholder="Prompt musica marketing" />
          <input id="musicMood" value="cinematic" />
          <input id="musicDuration" type="number" value="8" min="1" max="60" />
          <button id="runMusicBtn">Prepara musica</button>
        </div>
      </div>

      <div class="panel">
        <h2>Video Agent</h2>
        <div class="form-grid">
          <input id="videoPrompt" placeholder="Prompt video marketing" />
          <input id="videoFormat" value="promo" />
          <input id="videoDuration" type="number" value="4" min="1" max="30" />
          <button id="runVideoBtn">Prepara video</button>
        </div>
      </div>
    </div>

    <div class="stack">
      <div class="panel">
        <h2>Output</h2>
        <div class="box" id="outputBox">Nessun output.</div>
      </div>

      <div class="panel">
        <h2>Campaigns</h2>
        <div class="box" id="campaignsBox">Caricamento campaigns...</div>
      </div>

      <div class="panel">
        <h2>Logs</h2>
        <div class="box" id="logsBox">Caricamento logs...</div>
      </div>
    </div>
  </div>
</div>

<script>
const ui = {
  healthBadge: document.getElementById("healthBadge"),
  statusBox: document.getElementById("statusBox"),
  outputBox: document.getElementById("outputBox"),
  campaignsBox: document.getElementById("campaignsBox"),
  logsBox: document.getElementById("logsBox")
};

async function refresh() {
  try {
    const health = await window.marketingSuite.health();
    const campaigns = await window.marketingSuite.campaigns();
    const logs = await window.marketingSuite.logs();

    ui.healthBadge.textContent = `ONLINE // ${new Date().toLocaleTimeString()}`;
    ui.statusBox.textContent = JSON.stringify(health, null, 2);
    ui.campaignsBox.textContent = JSON.stringify(campaigns, null, 2);
    ui.logsBox.textContent = logs.lines ? logs.lines.join("\\n") : JSON.stringify(logs, null, 2);
  } catch (err) {
    ui.healthBadge.textContent = "OFFLINE";
    ui.statusBox.textContent = err.message;
  }
}

document.getElementById("startAIHubBtn").addEventListener("click", async () => {
  const out = await window.marketingSuite.startAIHub();
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1000);
});

document.getElementById("startServerBtn").addEventListener("click", async () => {
  const out = await window.marketingSuite.startMarketingServer();
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1000);
});

document.getElementById("refreshBtn").addEventListener("click", refresh);

document.getElementById("runCampaignBtn").addEventListener("click", async () => {
  const concept = document.getElementById("campaignConcept").value.trim();
  const model = document.getElementById("campaignModel").value;
  const out = await window.marketingSuite.campaignOrchestrator(concept, model);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 800);
});

document.getElementById("runTextBtn").addEventListener("click", async () => {
  const prompt = document.getElementById("textPrompt").value.trim();
  const model = document.getElementById("textModel").value;
  const out = await window.marketingSuite.textAgent(prompt, model);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 800);
});

document.getElementById("runMusicBtn").addEventListener("click", async () => {
  const prompt = document.getElementById("musicPrompt").value.trim();
  const mood = document.getElementById("musicMood").value.trim();
  const duration = Number(document.getElementById("musicDuration").value || 8);
  const out = await window.marketingSuite.musicAgent(prompt, mood, duration);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 800);
});

document.getElementById("runVideoBtn").addEventListener("click", async () => {
  const prompt = document.getElementById("videoPrompt").value.trim();
  const format = document.getElementById("videoFormat").value.trim();
  const duration = Number(document.getElementById("videoDuration").value || 4);
  const out = await window.marketingSuite.videoAgent(prompt, duration, format);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 800);
});

document.getElementById("openSuiteBtn").addEventListener("click", () => window.marketingSuite.openPath("C:\\SuiteV17\\MarketingSuite"));
document.getElementById("openTextBtn").addEventListener("click", () => window.marketingSuite.openPath("C:\\SuiteV17\\MarketingSuite\\output\\text"));
document.getElementById("openMusicBtn").addEventListener("click", () => window.marketingSuite.openPath("C:\\SuiteV17\\MarketingSuite\\output\\music"));
document.getElementById("openVideoBtn").addEventListener("click", () => window.marketingSuite.openPath("C:\\SuiteV17\\MarketingSuite\\output\\video"));
document.getElementById("openCampaignsBtn").addEventListener("click", () => window.marketingSuite.openPath("C:\\SuiteV17\\MarketingSuite\\output\\campaigns"));

refresh();
setInterval(refresh, 10000);
</script>
</body>
</html>
'@

$launchPs1Content = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\MarketingSuite"

if (!(Test-Path ".\UserData")) {
    New-Item -ItemType Directory -Force -Path ".\UserData" | Out-Null
}

Start-Process node -ArgumentList ".\marketing_server.js" -WorkingDirectory "C:\SuiteV17\MarketingSuite" | Out-Null
Start-Sleep -Seconds 1

$env:ELECTRON_USER_DATA_DIR = "C:\SuiteV17\MarketingSuite\UserData"
$env:ELECTRON_DISABLE_GPU   = "1"

npm start -- --disable-gpu
'@

$launchBatContent = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\MarketingSuite\Launch-MarketingSuite.ps1"
'@

Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
Set-Content -Path $PackagePath -Value $packageJson -Encoding UTF8
Set-Content -Path $ServerPath -Value $serverJs -Encoding UTF8
Set-Content -Path $MainPath -Value $mainJs -Encoding UTF8
Set-Content -Path $PreloadPath -Value $preloadJs -Encoding UTF8
Set-Content -Path $IndexPath -Value $indexHtml -Encoding UTF8
Set-Content -Path $LaunchPs1 -Value $launchPs1Content -Encoding UTF8
Set-Content -Path $LaunchBat -Value $launchBatContent -Encoding ASCII
Set-Content -Path $DesktopBat -Value $launchBatContent -Encoding ASCII

Set-Location $Suite
npm install | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH MARKETING SUITE COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Cartella: C:\SuiteV17\MarketingSuite"
Write-Host "Launcher Desktop: $DesktopBat"
Write-Host ""
Write-Host "Avvio:"
Write-Host '& "$HOME\Desktop\SuiteV17 Marketing Suite.bat"'