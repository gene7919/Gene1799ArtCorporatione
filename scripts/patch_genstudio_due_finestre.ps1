$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // GENSTUDIO DUE FINESTRE PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$ElectronApp = Join-Path $Root "ElectronApp"
$GenStudio = Join-Path $Root "GenStudio"
$GenOutput = Join-Path $GenStudio "output"
$GenText = Join-Path $GenOutput "text"
$GenAudio = Join-Path $GenOutput "audio"
$GenVideo = Join-Path $GenOutput "video"
$GenJobs = Join-Path $GenOutput "jobs"
$GenSkills = Join-Path $GenStudio "skills"
$GenLogs = Join-Path $GenStudio "logs"

$ServerPath = Join-Path $GenStudio "genstudio_server.js"
$PackagePath = Join-Path $GenStudio "package.json"
$ConfigPath = Join-Path $GenStudio "config.json"
$LaunchPs1 = Join-Path $GenStudio "Launch-GenStudio.ps1"
$LaunchBat = Join-Path $GenStudio "Launch-GenStudio.bat"

$ElectronMain = Join-Path $ElectronApp "main.js"
$ElectronPreload = Join-Path $ElectronApp "preload.js"
$ElectronIndex = Join-Path $ElectronApp "index.html"
$AiStudioHtml = Join-Path $ElectronApp "genstudio.html"

$DesktopLauncher = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 GenStudio.bat"

foreach ($dir in @($GenStudio, $GenOutput, $GenText, $GenAudio, $GenVideo, $GenJobs, $GenSkills, $GenLogs)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
foreach ($f in @($ServerPath, $PackagePath, $ConfigPath, $LaunchPs1, $LaunchBat, $ElectronMain, $ElectronPreload, $ElectronIndex, $AiStudioHtml)) {
    if (Test-Path $f) {
        Copy-Item $f "$f.bak_$timestamp" -Force
    }
}

$configJson = @'
{
  "server": {
    "port": 3021
  },
  "aihub": {
    "baseUrl": "http://127.0.0.1:3020"
  },
  "ollama": {
    "defaultModel": "qwen3:4b",
    "preferredModel": "qwen3:8b",
    "embeddingModel": "embeddinggemma:latest"
  },
  "paths": {
    "root": "C:\\SuiteV17\\GenStudio",
    "textOutput": "C:\\SuiteV17\\GenStudio\\output\\text",
    "audioOutput": "C:\\SuiteV17\\GenStudio\\output\\audio",
    "videoOutput": "C:\\SuiteV17\\GenStudio\\output\\video",
    "jobsOutput": "C:\\SuiteV17\\GenStudio\\output\\jobs",
    "logs": "C:\\SuiteV17\\GenStudio\\logs"
  },
  "audio": {
    "engine": "musicgen",
    "enabled": false,
    "script": "C:\\SuiteV17\\GenStudio\\skills\\audio_generate.ps1",
    "defaultDuration": 8
  },
  "video": {
    "engine": "ltx-video",
    "enabled": false,
    "script": "C:\\SuiteV17\\GenStudio\\skills\\video_generate.ps1",
    "defaultDuration": 4,
    "defaultFps": 24,
    "defaultResolution": "768x432"
  }
}
'@

$packageJson = @'
{
  "name": "suitev17-genstudio",
  "version": "1.0.0",
  "description": "GenStudio creativo per Suite V17",
  "main": "genstudio_server.js",
  "scripts": {
    "start": "node genstudio_server.js"
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
const { exec } = require("child_process");

const app = express();
app.use(cors());
app.use(express.json({ limit: "5mb" }));

const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"));
const PORT = Number(config.server?.port || 3021);
const AIHUB = config.aihub?.baseUrl || "http://127.0.0.1:3020";

function ensureDir(p) {
  try { fs.mkdirSync(p, { recursive: true }); } catch {}
}

function nowStamp() {
  const d = new Date();
  const pad = n => String(n).padStart(2, "0");
  return `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}_${pad(d.getHours())}${pad(d.getMinutes())}${pad(d.getSeconds())}`;
}

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

function writeJson(p, data) {
  fs.writeFileSync(p, JSON.stringify(data, null, 2), "utf8");
}

function appendLog(name, text) {
  const logFile = path.join(config.paths.logs, `${name}.log`);
  fs.appendFileSync(logFile, `[${new Date().toISOString()}] ${text}\n`, "utf8");
}

function execPromise(command, cwd) {
  return new Promise((resolve) => {
    exec(command, { cwd, windowsHide: true }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        code: error && typeof error.code !== "undefined" ? error.code : 0,
        stdout: stdout || "",
        stderr: stderr || "",
        error: error ? error.message : ""
      });
    });
  });
}

function jobPath(id) {
  return path.join(config.paths.jobsOutput, `${id}.json`);
}

function saveJob(job) {
  writeJson(jobPath(job.id), job);
}

function listJobs() {
  ensureDir(config.paths.jobsOutput);
  return fs.readdirSync(config.paths.jobsOutput)
    .filter(f => f.endsWith(".json"))
    .map(f => readJsonSafe(path.join(config.paths.jobsOutput, f), null))
    .filter(Boolean)
    .sort((a, b) => String(b.createdAt).localeCompare(String(a.createdAt)));
}

app.get("/health", async (req, res) => {
  let aihub = { ok: false };
  try {
    const out = await axios.get(`${AIHUB}/health`, { timeout: 4000 });
    aihub = { ok: true, status: out.status, data: out.data };
  } catch (err) {
    aihub = { ok: false, error: err.message };
  }

  res.json({
    ok: true,
    service: "GenStudio",
    now: new Date().toISOString(),
    aihub
  });
});

app.get("/api/config", (req, res) => {
  res.json({
    ok: true,
    config
  });
});

app.get("/api/jobs", (req, res) => {
  res.json({
    ok: true,
    jobs: listJobs()
  });
});

app.post("/api/generate/text", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const model = req.body.model || config.ollama.defaultModel;
    const filenamePrefix = req.body.filenamePrefix || "text_gen";

    if (!prompt) {
      return res.status(400).json({ ok: false, error: "prompt mancante" });
    }

    const id = `text_${nowStamp()}`;
    const job = {
      id,
      type: "text",
      status: "running",
      createdAt: new Date().toISOString(),
      prompt,
      model
    };
    saveJob(job);

    appendLog("genstudio", `TEXT job start ${id}`);

    const out = await axios.post(`${AIHUB}/api/generate/social`, {
      model,
      prompt_override: prompt
    }, { timeout: 120000 }).catch(async () => {
      return axios.post(`${AIHUB}/api/analyze/token`, { model }, { timeout: 120000 });
    });

    const outputFile = path.join(config.paths.textOutput, `${filenamePrefix}_${nowStamp()}.json`);
    writeJson(outputFile, out.data);

    job.status = "done";
    job.finishedAt = new Date().toISOString();
    job.outputFile = outputFile;
    job.result = out.data;
    saveJob(job);

    appendLog("genstudio", `TEXT job done ${id} -> ${outputFile}`);

    res.json({ ok: true, job });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/generate/text-direct", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const model = req.body.model || config.ollama.defaultModel;

    if (!prompt) {
      return res.status(400).json({ ok: false, error: "prompt mancante" });
    }

    const id = `textdirect_${nowStamp()}`;
    const job = {
      id,
      type: "text-direct",
      status: "running",
      createdAt: new Date().toISOString(),
      prompt,
      model
    };
    saveJob(job);

    const response = await axios.post(`${config.aihub.baseUrl}/api/models`, {}, { timeout: 10000 }).catch(() => null);

    const textPayload = {
      prompt,
      model,
      note: "Usa AIHub come backend Ollama locale"
    };

    const outputFile = path.join(config.paths.textOutput, `prompt_${nowStamp()}.json`);
    writeJson(outputFile, {
      request: textPayload,
      modelStatus: response ? response.data : { ok: false }
    });

    job.status = "done";
    job.finishedAt = new Date().toISOString();
    job.outputFile = outputFile;
    saveJob(job);

    res.json({ ok: true, job });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/generate/audio", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const duration = Number(req.body.duration || config.audio.defaultDuration || 8);
    const style = String(req.body.style || "cinematic");
    const id = `audio_${nowStamp()}`;

    if (!prompt) {
      return res.status(400).json({ ok: false, error: "prompt mancante" });
    }

    const job = {
      id,
      type: "audio",
      status: "queued",
      createdAt: new Date().toISOString(),
      prompt,
      duration,
      style,
      engine: config.audio.engine
    };
    saveJob(job);

    const script = config.audio.script;
    const outputFile = path.join(config.paths.audioOutput, `${id}.wav`);

    if (!config.audio.enabled) {
      job.status = "prepared";
      job.outputFile = outputFile;
      job.note = "Engine audio non ancora abilitato. Skill e job preparati."
      saveJob(job);

      return res.json({ ok: true, job });
    }

    const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${script}" -Prompt "${prompt.Replace('"','`"')}" -Duration ${duration} -Style "${style}" -OutputFile "${outputFile}"`;
    const run = await execPromise(cmd, __dirname);

    job.status = run.ok ? "done" : "failed";
    job.finishedAt = new Date().toISOString();
    job.outputFile = outputFile;
    job.exec = run;
    saveJob(job);

    res.json({ ok: true, job });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.post("/api/generate/video", async (req, res) => {
  try {
    const prompt = String(req.body.prompt || "").trim();
    const duration = Number(req.body.duration || config.video.defaultDuration || 4);
    const fps = Number(req.body.fps || config.video.defaultFps || 24);
    const resolution = String(req.body.resolution || config.video.defaultResolution || "768x432");
    const id = `video_${nowStamp()}`;

    if (!prompt) {
      return res.status(400).json({ ok: false, error: "prompt mancante" });
    }

    const job = {
      id,
      type: "video",
      status: "queued",
      createdAt: new Date().toISOString(),
      prompt,
      duration,
      fps,
      resolution,
      engine: config.video.engine
    };
    saveJob(job);

    const script = config.video.script;
    const outputFile = path.join(config.paths.videoOutput, `${id}.mp4`);

    if (!config.video.enabled) {
      job.status = "prepared";
      job.outputFile = outputFile;
      job.note = "Engine video non ancora abilitato. Skill e job preparati."
      saveJob(job);

      return res.json({ ok: true, job });
    }

    const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${script}" -Prompt "${prompt.Replace('"','`"')}" -Duration ${duration} -Fps ${fps} -Resolution "${resolution}" -OutputFile "${outputFile}"`;
    const run = await execPromise(cmd, __dirname);

    job.status = run.ok ? "done" : "failed";
    job.finishedAt = new Date().toISOString();
    job.outputFile = outputFile;
    job.exec = run;
    saveJob(job);

    res.json({ ok: true, job });
  } catch (err) {
    res.status(500).json({ ok: false, error: err.message });
  }
});

app.get("/api/logs", (req, res) => {
  const logFile = path.join(config.paths.logs, "genstudio.log");
  const txt = readTextSafe(logFile, "");
  res.json({
    ok: true,
    lines: txt.split(/\r?\n/).filter(Boolean).slice(-150)
  });
});

app.listen(PORT, () => {
  ensureDir(config.paths.textOutput);
  ensureDir(config.paths.audioOutput);
  ensureDir(config.paths.videoOutput);
  ensureDir(config.paths.jobsOutput);
  ensureDir(config.paths.logs);
  console.log(`[GenStudio] online su http://127.0.0.1:${PORT}`);
});
'@

$audioSkill = @'
param(
    [string]$Prompt,
    [int]$Duration = 8,
    [string]$Style = "cinematic",
    [string]$OutputFile = ""
)

Write-Host "========================================="
Write-Host " GenStudio Audio Skill"
Write-Host "========================================="
Write-Host "Prompt: $Prompt"
Write-Host "Duration: $Duration"
Write-Host "Style: $Style"
Write-Host "Output: $OutputFile"
Write-Host ""
Write-Host "Questa skill è pronta per essere collegata a MusicGen / AudioCraft."
Write-Host "Per ora crea solo il job preparato."
'@

$videoSkill = @'
param(
    [string]$Prompt,
    [int]$Duration = 4,
    [int]$Fps = 24,
    [string]$Resolution = "768x432",
    [string]$OutputFile = ""
)

Write-Host "========================================="
Write-Host " GenStudio Video Skill"
Write-Host "========================================="
Write-Host "Prompt: $Prompt"
Write-Host "Duration: $Duration"
Write-Host "FPS: $Fps"
Write-Host "Resolution: $Resolution"
Write-Host "Output: $OutputFile"
Write-Host ""
Write-Host "Questa skill è pronta per essere collegata a LTX-Video."
Write-Host "Per ora crea solo il job preparato."
'@

$launchPs1Content = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\GenStudio"
Start-Process node -ArgumentList ".\genstudio_server.js" -WorkingDirectory "C:\SuiteV17\GenStudio"
'@

$launchBatContent = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\GenStudio\Launch-GenStudio.ps1"
'@

Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
Set-Content -Path $PackagePath -Value $packageJson -Encoding UTF8
Set-Content -Path $ServerPath -Value $serverJs -Encoding UTF8
Set-Content -Path (Join-Path $GenSkills "audio_generate.ps1") -Value $audioSkill -Encoding UTF8
Set-Content -Path (Join-Path $GenSkills "video_generate.ps1") -Value $videoSkill -Encoding UTF8
Set-Content -Path $LaunchPs1 -Value $launchPs1Content -Encoding UTF8
Set-Content -Path $LaunchBat -Value $launchBatContent -Encoding ASCII
Set-Content -Path $DesktopLauncher -Value $launchBatContent -Encoding ASCII

Write-Host "GenStudio creato." -ForegroundColor Green

if (!(Test-Path $ElectronApp)) {
    throw "ElectronApp non trovato in C:\SuiteV17\ElectronApp"
}

$electronMainContent = @'
const { app, BrowserWindow, shell, Menu } = require("electron");
const path = require("path");
const fs = require("fs");

let controlRoomWindow = null;
let genStudioWindow = null;

function ensureDir(dir) {
  try { fs.mkdirSync(dir, { recursive: true }); } catch {}
}

app.commandLine.appendSwitch("disable-gpu");
app.commandLine.appendSwitch("disable-software-rasterizer");

function createControlRoomWindow() {
  controlRoomWindow = new BrowserWindow({
    width: 1600,
    height: 960,
    minWidth: 1200,
    minHeight: 760,
    backgroundColor: "#050806",
    title: "Suite V17 // Control Room",
    autoHideMenuBar: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  controlRoomWindow.loadFile(path.join(__dirname, "index.html"));

  controlRoomWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });
}

function createGenStudioWindow() {
  if (genStudioWindow && !genStudioWindow.isDestroyed()) {
    genStudioWindow.focus();
    return;
  }

  genStudioWindow = new BrowserWindow({
    width: 1500,
    height: 940,
    minWidth: 1150,
    minHeight: 740,
    backgroundColor: "#06070c",
    title: "Suite V17 // AI Studio",
    autoHideMenuBar: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  genStudioWindow.loadFile(path.join(__dirname, "genstudio.html"));

  genStudioWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: "deny" };
  });

  genStudioWindow.on("closed", () => {
    genStudioWindow = null;
  });
}

function buildMenu() {
  const template = [
    {
      label: "Suite V17",
      submenu: [
        { label: "Apri Control Room", click: () => controlRoomWindow ? controlRoomWindow.focus() : createControlRoomWindow() },
        { label: "Apri AI Studio", click: () => createGenStudioWindow() },
        { type: "separator" },
        { role: "quit", label: "Esci" }
      ]
    },
    {
      label: "Finestra",
      submenu: [
        { role: "reload", label: "Ricarica" },
        { role: "toggledevtools", label: "DevTools" },
        { role: "minimize", label: "Minimizza" }
      ]
    }
  ];

  Menu.setApplicationMenu(Menu.buildFromTemplate(template));
}

app.whenReady().then(() => {
  ensureDir(path.join(__dirname, "UserData"));
  buildMenu();
  createControlRoomWindow();

  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createControlRoomWindow();
  });
});

app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
'@

$electronPreloadContent = @'
const { contextBridge, shell } = require("electron");
const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
const { exec } = require("child_process");

const ROOT = "C:\\SuiteV17";

const PATHS = {
  tokenModule: path.join(ROOT, "TokenModule"),
  tokenData: path.join(ROOT, "TokenModule", "token_data.json"),
  tokenConfig: path.join(ROOT, "TokenModule", "config.json"),
  tokenLog: path.join(ROOT, "TokenModule", "token_monitor.log"),
  tokenServer: path.join(ROOT, "TokenModule", "server.js"),
  tokenMonitor: path.join(ROOT, "TokenModule", "token_monitor.js"),

  browserModule: path.join(ROOT, "BrowserModule"),
  browserServer: path.join(ROOT, "BrowserModule", "browser_server.js"),

  socialHub: path.join(ROOT, "SocialHubV1"),
  socialConfig: path.join(ROOT, "SocialHubV1", "config", "appsettings.json"),

  aihub: path.join(ROOT, "AIHub"),
  genstudio: path.join(ROOT, "GenStudio"),
  genstudioOutput: path.join(ROOT, "GenStudio", "output")
};

function exists(p) {
  try { return fs.existsSync(p); } catch { return false; }
}

function readJsonSafe(p, fallback = {}) {
  try { return JSON.parse(fs.readFileSync(p, "utf8")); } catch { return fallback; }
}

function readTextSafe(p, fallback = "") {
  try { return fs.readFileSync(p, "utf8"); } catch { return fallback; }
}

function tailLines(text, count = 100) {
  return String(text || "").split(/\r?\n/).filter(Boolean).slice(-count);
}

function probeUrl(url, timeout = 3000) {
  return new Promise((resolve) => {
    try {
      const lib = url.startsWith("https") ? https : http;
      const req = lib.get(url, { timeout }, (res) => {
        resolve({ ok: res.statusCode >= 200 && res.statusCode < 400, status: res.statusCode });
        res.resume();
      });
      req.on("error", (err) => resolve({ ok: false, error: err.message }));
      req.on("timeout", () => {
        req.destroy();
        resolve({ ok: false, error: "timeout" });
      });
    } catch (err) {
      resolve({ ok: false, error: err.message });
    }
  });
}

function execPromise(command, cwd) {
  return new Promise((resolve) => {
    exec(command, { cwd, windowsHide: true }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        code: error && typeof error.code !== "undefined" ? error.code : 0,
        stdout: stdout || "",
        stderr: stderr || "",
        error: error ? error.message : ""
      });
    });
  });
}

function startNodeScript(scriptPath, workingDir) {
  return new Promise((resolve) => {
    const cmd = `Start-Process node -ArgumentList '${scriptPath}' -WorkingDirectory '${workingDir}'`;
    exec(`powershell -NoProfile -ExecutionPolicy Bypass -Command "${cmd}"`, { cwd: workingDir, windowsHide: true }, (error, stdout, stderr) => {
      resolve({
        ok: !error,
        stdout: stdout || "",
        stderr: stderr || "",
        error: error ? error.message : ""
      });
    });
  });
}

async function getSystemSnapshot() {
  const tokenData = readJsonSafe(PATHS.tokenData, { status: "missing" });
  const tokenConfig = readJsonSafe(PATHS.tokenConfig, {});
  const socialConfig = readJsonSafe(PATHS.socialConfig, {});
  const browserHealth = await probeUrl("http://127.0.0.1:8093/health");
  const tokenDashHealth = await probeUrl("http://127.0.0.1:3018/health");
  const aihubHealth = await probeUrl("http://127.0.0.1:3020/health");
  const genstudioHealth = await probeUrl("http://127.0.0.1:3021/health");

  return {
    now: new Date().toISOString(),
    modules: {
      token: {
        data: tokenData,
        config: {
          telegramEnabled: !!tokenConfig.telegram?.enabled,
          socialEnabled: !!tokenConfig.social?.enabled
        },
        dashboardHealth: tokenDashHealth
      },
      browser: { health: browserHealth },
      social: {
        config: socialConfig
      },
      aihub: { health: aihubHealth },
      genstudio: { health: genstudioHealth }
    },
    logs: {
      token: tailLines(readTextSafe(PATHS.tokenLog, ""), 80)
    },
    paths: PATHS
  };
}

async function startTokenMonitor() {
  return startNodeScript(".\\token_monitor.js", PATHS.tokenModule);
}

async function startTokenDashboardServer() {
  return startNodeScript(".\\server.js", PATHS.tokenModule);
}

async function startBrowserModule() {
  return startNodeScript(".\\browser_server.js", PATHS.browserModule);
}

async function startAIHub() {
  return startNodeScript(".\\ollama_router.js", PATHS.aihub);
}

async function startGenStudio() {
  return startNodeScript(".\\genstudio_server.js", PATHS.genstudio);
}

async function testTelegram() {
  const cfg = readJsonSafe(PATHS.tokenConfig, {});
  const token = cfg.telegram?.botToken;
  const chatId = cfg.telegram?.chatId;

  if (!token || !chatId) {
    return { ok: false, error: "botToken o chatId mancanti" };
  }

  const payload = JSON.stringify({
    chat_id: chatId,
    text: "🔥 Suite V17 Control Room: test Telegram OK"
  });

  return new Promise((resolve) => {
    const req = https.request({
      hostname: "api.telegram.org",
      path: `/bot${token}/sendMessage`,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(payload)
      }
    }, (res) => {
      let body = "";
      res.on("data", chunk => body += chunk);
      res.on("end", () => {
        try { resolve(JSON.parse(body)); }
        catch { resolve({ ok: false, raw: body }); }
      });
    });

    req.on("error", (err) => resolve({ ok: false, error: err.message }));
    req.write(payload);
    req.end();
  });
}

async function testWebhook() {
  const cfg = readJsonSafe(PATHS.tokenConfig, {});
  const webhook = cfg.social?.webhook;

  if (!webhook) {
    return { ok: false, error: "webhook mancante" };
  }

  const payload = JSON.stringify({
    platform: "telegram",
    title: "Suite V17 Control Room Test",
    source: "Electron",
    time: new Date().toISOString(),
    text: "✅ Webhook test da Suite V17"
  });

  return new Promise((resolve) => {
    try {
      const u = new URL(webhook);
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
        let body = "";
        res.on("data", chunk => body += chunk);
        res.on("end", () => resolve({ ok: res.statusCode >= 200 && res.statusCode < 300, status: res.statusCode, body }));
      });

      req.on("error", (err) => resolve({ ok: false, error: err.message }));
      req.write(payload);
      req.end();
    } catch (err) {
      resolve({ ok: false, error: err.message });
    }
  });
}

async function genStudioHealth() {
  return probeUrl("http://127.0.0.1:3021/health");
}

async function genStudioJobs() {
  try {
    const res = await fetchJson("http://127.0.0.1:3021/api/jobs");
    return res;
  } catch (err) {
    return { ok: false, error: err.message };
  }
}

async function genStudioGenerateText(prompt, model) {
  return postJson("http://127.0.0.1:3021/api/generate/text", { prompt, model });
}

async function genStudioGenerateAudio(prompt, duration, style) {
  return postJson("http://127.0.0.1:3021/api/generate/audio", { prompt, duration, style });
}

async function genStudioGenerateVideo(prompt, duration, fps, resolution) {
  return postJson("http://127.0.0.1:3021/api/generate/video", { prompt, duration, fps, resolution });
}

async function genStudioLogs() {
  try {
    return await fetchJson("http://127.0.0.1:3021/api/logs");
  } catch (err) {
    return { ok: false, error: err.message };
  }
}

function fetchJson(url) {
  return new Promise((resolve, reject) => {
    const lib = url.startsWith("https") ? https : http;
    const req = lib.get(url, (res) => {
      let data = "";
      res.on("data", chunk => data += chunk);
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
      res.on("data", chunk => data += chunk);
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

contextBridge.exposeInMainWorld("suitev17", {
  getSystemSnapshot,
  startTokenMonitor,
  startTokenDashboardServer,
  startBrowserModule,
  startAIHub,
  startGenStudio,
  testTelegram,
  testWebhook,
  genStudioHealth,
  genStudioJobs,
  genStudioGenerateText,
  genStudioGenerateAudio,
  genStudioGenerateVideo,
  genStudioLogs,
  openPath: (target) => shell.openPath(target),
  openExternal: (url) => shell.openExternal(url)
});
'@

$genStudioHtmlContent = @'
<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Suite V17 // AI Studio</title>
  <style>
    :root{
      --bg:#090a12;
      --panel:rgba(13,14,24,.95);
      --line:#7aa7ff;
      --text:#dfe8ff;
      --muted:#90a0c4;
      --ok:#76ffb3;
      --warn:#ffd36e;
      --bad:#ff7777;
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      background:
        radial-gradient(circle at top, rgba(80,120,255,.08), transparent 35%),
        linear-gradient(180deg,#04050a 0%,#0a0c16 100%);
      color:var(--text);
      font-family:Consolas,"Courier New",monospace;
    }
    .wrap{max-width:1700px;margin:0 auto;padding:18px}
    .topbar,.panel{
      background:var(--panel);
      border:1px solid rgba(122,167,255,.22);
      border-radius:18px;
      box-shadow:0 0 24px rgba(122,167,255,.08);
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
      background:rgba(122,167,255,.08);
      border:1px solid rgba(122,167,255,.2);
      font-size:12px
    }
    .grid{display:grid;grid-template-columns:360px 1fr 420px;gap:16px}
    .panel{padding:16px}
    .stack{display:grid;gap:16px}
    h2{margin:0 0 14px;font-size:18px}
    textarea,input,select{
      width:100%;
      border-radius:12px;
      border:1px solid rgba(122,167,255,.18);
      background:rgba(0,0,0,.24);
      color:var(--text);
      padding:10px 12px;
      font-family:inherit;
      font-size:13px
    }
    textarea{min-height:130px;resize:vertical}
    button{
      width:100%;padding:11px 12px;border-radius:12px;
      border:1px solid rgba(122,167,255,.22);
      background:rgba(122,167,255,.08);
      color:var(--text);cursor:pointer;font-family:inherit
    }
    button:hover{background:rgba(122,167,255,.14)}
    .btn-grid,.form-grid,.list{display:grid;gap:10px}
    .jobs,.logs,.output{
      min-height:240px;max-height:460px;overflow:auto;white-space:pre-wrap;
      font-size:12px;line-height:1.45;background:rgba(0,0,0,.28);
      border:1px solid rgba(122,167,255,.12);border-radius:14px;padding:12px
    }
    .tabs{display:flex;gap:10px;flex-wrap:wrap;margin-bottom:14px}
    .tabbtn{width:auto;padding:10px 14px}
    .tab{display:none}
    .tab.active{display:block}
    .small{font-size:12px;color:var(--muted)}
    @media (max-width:1280px){.grid{grid-template-columns:1fr}}
  </style>
</head>
<body>
<div class="wrap">
  <div class="topbar">
    <div>
      <div class="title">SUITE V17 // AI STUDIO</div>
      <div class="sub">Testi, audio, video, jobs, output separati</div>
    </div>
    <div class="badge" id="healthBadge">BOOT...</div>
  </div>

  <div class="grid">
    <div class="stack">
      <div class="panel">
        <h2>Quick Actions</h2>
        <div class="btn-grid">
          <button id="startAIHubBtn">Avvia AIHub</button>
          <button id="startGenStudioBtn">Avvia GenStudio</button>
          <button id="refreshBtn">Aggiorna stato</button>
          <button id="openGenStudioBtn">Apri cartella GenStudio</button>
          <button id="openTextBtn">Apri output text</button>
          <button id="openAudioBtn">Apri output audio</button>
          <button id="openVideoBtn">Apri output video</button>
          <button id="openJobsBtn">Apri jobs</button>
        </div>
      </div>

      <div class="panel">
        <h2>Stato</h2>
        <div class="list small">
          <div>AIHub: <span id="aihubStatus">-</span></div>
          <div>GenStudio: <span id="genstudioStatus">-</span></div>
          <div>Output text: <span id="textPath">-</span></div>
          <div>Output audio: <span id="audioPath">-</span></div>
          <div>Output video: <span id="videoPath">-</span></div>
        </div>
      </div>
    </div>

    <div class="stack">
      <div class="panel">
        <h2>Generatori</h2>
        <div class="tabs">
          <button class="tabbtn" data-tab="textTab">Testi</button>
          <button class="tabbtn" data-tab="audioTab">Audio</button>
          <button class="tabbtn" data-tab="videoTab">Video</button>
        </div>

        <div id="textTab" class="tab active">
          <div class="form-grid">
            <select id="textModel">
              <option value="qwen3:4b">qwen3:4b</option>
              <option value="qwen3:8b">qwen3:8b</option>
            </select>
            <textarea id="textPrompt" placeholder="Scrivi il prompt testo..."></textarea>
            <button id="generateTextBtn">Genera testo</button>
          </div>
        </div>

        <div id="audioTab" class="tab">
          <div class="form-grid">
            <input id="audioPrompt" placeholder="Prompt audio / musica / sfx" />
            <input id="audioDuration" type="number" value="8" min="1" max="60" />
            <input id="audioStyle" value="cinematic" />
            <button id="generateAudioBtn">Prepara job audio</button>
          </div>
        </div>

        <div id="videoTab" class="tab">
          <div class="form-grid">
            <input id="videoPrompt" placeholder="Prompt video / clip" />
            <input id="videoDuration" type="number" value="4" min="1" max="30" />
            <input id="videoFps" type="number" value="24" min="1" max="60" />
            <input id="videoResolution" value="768x432" />
            <button id="generateVideoBtn">Prepara job video</button>
          </div>
        </div>
      </div>

      <div class="panel">
        <h2>Output</h2>
        <div class="output" id="outputBox">Nessun output.</div>
      </div>
    </div>

    <div class="stack">
      <div class="panel">
        <h2>Jobs</h2>
        <div class="jobs" id="jobsBox">Caricamento jobs...</div>
      </div>
      <div class="panel">
        <h2>Logs</h2>
        <div class="logs" id="logsBox">Caricamento logs...</div>
      </div>
    </div>
  </div>
</div>

<script>
const ui = {
  healthBadge: document.getElementById("healthBadge"),
  aihubStatus: document.getElementById("aihubStatus"),
  genstudioStatus: document.getElementById("genstudioStatus"),
  textPath: document.getElementById("textPath"),
  audioPath: document.getElementById("audioPath"),
  videoPath: document.getElementById("videoPath"),
  jobsBox: document.getElementById("jobsBox"),
  logsBox: document.getElementById("logsBox"),
  outputBox: document.getElementById("outputBox")
};

document.querySelectorAll(".tabbtn").forEach(btn => {
  btn.addEventListener("click", () => {
    const tab = btn.dataset.tab;
    document.querySelectorAll(".tab").forEach(t => t.classList.remove("active"));
    document.getElementById(tab).classList.add("active");
  });
});

async function refresh() {
  const snap = await window.suitev17.getSystemSnapshot();
  const genHealth = await window.suitev17.genStudioHealth();
  const logs = await window.suitev17.genStudioLogs();
  const jobs = await window.suitev17.genStudioJobs();

  ui.healthBadge.textContent = `AI Studio // ${new Date().toLocaleTimeString()}`;
  ui.aihubStatus.textContent = snap.modules.aihub.health.ok ? "online" : (snap.modules.aihub.health.error || "offline");
  ui.genstudioStatus.textContent = genHealth.ok ? "online" : (genHealth.error || "offline");
  ui.textPath.textContent = "C:\\SuiteV17\\GenStudio\\output\\text";
  ui.audioPath.textContent = "C:\\SuiteV17\\GenStudio\\output\\audio";
  ui.videoPath.textContent = "C:\\SuiteV17\\GenStudio\\output\\video";

  ui.jobsBox.textContent = JSON.stringify(jobs, null, 2);
  ui.logsBox.textContent = logs.lines ? logs.lines.join("\n") : JSON.stringify(logs, null, 2);
}

document.getElementById("startAIHubBtn").addEventListener("click", async () => {
  const out = await window.suitev17.startAIHub();
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1200);
});

document.getElementById("startGenStudioBtn").addEventListener("click", async () => {
  const out = await window.suitev17.startGenStudio();
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1200);
});

document.getElementById("refreshBtn").addEventListener("click", refresh);

document.getElementById("openGenStudioBtn").addEventListener("click", () => {
  window.suitev17.openPath("C:\\SuiteV17\\GenStudio");
});
document.getElementById("openTextBtn").addEventListener("click", () => {
  window.suitev17.openPath("C:\\SuiteV17\\GenStudio\\output\\text");
});
document.getElementById("openAudioBtn").addEventListener("click", () => {
  window.suitev17.openPath("C:\\SuiteV17\\GenStudio\\output\\audio");
});
document.getElementById("openVideoBtn").addEventListener("click", () => {
  window.suitev17.openPath("C:\\SuiteV17\\GenStudio\\output\\video");
});
document.getElementById("openJobsBtn").addEventListener("click", () => {
  window.suitev17.openPath("C:\\SuiteV17\\GenStudio\\output\\jobs");
});

document.getElementById("generateTextBtn").addEventListener("click", async () => {
  const prompt = document.getElementById("textPrompt").value.trim();
  const model = document.getElementById("textModel").value;
  const out = await window.suitev17.genStudioGenerateText(prompt, model);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1000);
});

document.getElementById("generateAudioBtn").addEventListener("click", async () => {
  const prompt = document.getElementById("audioPrompt").value.trim();
  const duration = Number(document.getElementById("audioDuration").value || 8);
  const style = document.getElementById("audioStyle").value.trim();
  const out = await window.suitev17.genStudioGenerateAudio(prompt, duration, style);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1000);
});

document.getElementById("generateVideoBtn").addEventListener("click", async () => {
  const prompt = document.getElementById("videoPrompt").value.trim();
  const duration = Number(document.getElementById("videoDuration").value || 4);
  const fps = Number(document.getElementById("videoFps").value || 24);
  const resolution = document.getElementById("videoResolution").value.trim();
  const out = await window.suitev17.genStudioGenerateVideo(prompt, duration, fps, resolution);
  ui.outputBox.textContent = JSON.stringify(out, null, 2);
  setTimeout(refresh, 1000);
});

refresh();
setInterval(refresh, 10000);
</script>
</body>
</html>
'@

Set-Content -Path $ElectronMain -Value $electronMainContent -Encoding UTF8
Set-Content -Path $ElectronPreload -Value $electronPreloadContent -Encoding UTF8
Set-Content -Path $AiStudioHtml -Value $genStudioHtmlContent -Encoding UTF8

Write-Host "ElectronApp aggiornato a due finestre." -ForegroundColor Green

Set-Location $GenStudio
npm install | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH GENSTUDIO COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "GenStudio: C:\SuiteV17\GenStudio"
Write-Host "Launcher Desktop: $DesktopLauncher"
Write-Host ""
Write-Host "Avvio GenStudio server:"
Write-Host '  powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\GenStudio\Launch-GenStudio.ps1"'
Write-Host ""
Write-Host "Health:"
Write-Host "  http://127.0.0.1:3021/health"
Write-Host ""
Write-Host "Per aprire ElectronApp:"
Write-Host '  cd C:\SuiteV17\ElectronApp'
Write-Host '  $env:ELECTRON_USER_DATA_DIR="C:\SuiteV17\ElectronApp\UserData"'
Write-Host '  $env:ELECTRON_DISABLE_GPU="1"'
Write-Host '  npm start -- --disable-gpu'