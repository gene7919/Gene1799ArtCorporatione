$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " MARKETING SUITE // GPU + DESKTOP PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$Suite = Join-Path $Root "MarketingSuite"

if (!(Test-Path $Suite)) {
    throw "MarketingSuite non trovata in $Suite"
}

$ServerPath   = Join-Path $Suite "marketing_server.js"
$PackagePath  = Join-Path $Suite "package.json"
$LaunchPs1    = Join-Path $Suite "Launch-MarketingSuite.ps1"
$LaunchBat    = Join-Path $Suite "Launch-MarketingSuite.bat"
$DesktopBat   = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 Marketing Suite.bat"

$AudioGpuSkill = "C:\SuiteV17\GenStudio\skills\audio_generate_gpu.ps1"
$VideoGpuSkill = "C:\SuiteV17\GenStudio\skills\video_generate_gpu.ps1"

foreach ($p in @($ServerPath,$PackagePath,$LaunchPs1,$LaunchBat)) {
    if (Test-Path $p) {
        Copy-Item $p "$p.bak_$(Get-Date -Format yyyyMMdd_HHmmss)" -Force
    }
}

$serverJs = @'
const fs = require("fs");
const path = require("path");
const express = require("express");
const cors = require("cors");
const axios = require("axios");
const { exec } = require("child_process");

const app = express();
app.use(cors());
app.use(express.json({ limit: "4mb" }));

const ROOT = "C:\\SuiteV17";
const config = JSON.parse(fs.readFileSync(path.join(__dirname, "config.json"), "utf8"));
const PORT = Number(config.server?.port || 3022);
const AIHUB = config.aihub?.baseUrl || "http://127.0.0.1:3020";

const AUDIO_GPU_SCRIPT = "C:\\SuiteV17\\GenStudio\\skills\\audio_generate_gpu.ps1";
const VIDEO_GPU_SCRIPT = "C:\\SuiteV17\\GenStudio\\skills\\video_generate_gpu.ps1";

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
    return fs.readFileSync(file, "utf8").split(/\r?\n/).filter(Boolean).slice(-count);
  } catch {
    return [];
  }
}

function logLine(text) {
  const file = path.join(config.paths.logs, "marketing_suite.log");
  fs.appendFileSync(file, `[${new Date().toISOString()}] ${text}\n`, "utf8");
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

function execPromise(command, cwd = __dirname) {
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

    const outputFile = path.join(config.paths.music, `music_gpu_${stamp()}.json`);
    const safePrompt = prompt.replace(/"/g, '\\"');
    const safeMood = mood.replace(/"/g, '\\"');

    const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${AUDIO_GPU_SCRIPT}" -Prompt "${safePrompt}" -Duration ${duration} -Style "${safeMood}" -OutputFile "${outputFile}"`;
    const run = await execPromise(cmd);

    logLine(`MUSIC agent GPU -> ${outputFile}`);

    res.json({
      ok: run.ok,
      outputFile,
      exec: run
    });
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

    const outputFile = path.join(config.paths.video, `video_gpu_${stamp()}.json`);
    const safePrompt = `${format}, ${prompt}`.replace(/"/g, '\\"');

    const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -File "${VIDEO_GPU_SCRIPT}" -Prompt "${safePrompt}" -Duration ${duration} -Fps 24 -Resolution "768x432" -OutputFile "${outputFile}"`;
    const run = await execPromise(cmd);

    logLine(`VIDEO agent GPU -> ${outputFile}`);

    res.json({
      ok: run.ok,
      outputFile,
      exec: run
    });
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
        engine: "audio_generate_gpu.ps1",
        status: "gpu-ready"
      },
      videoPlan: {
        prompt: `${concept}, promo clip, visual brand identity, cinematic campaign`,
        engine: "video_generate_gpu.ps1",
        status: "gpu-ready"
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

$package = @'
{
  "name": "suitev17-marketing-suite",
  "version": "1.1.0",
  "description": "Suite marketing separata per testi, musica e video",
  "main": "main.js",
  "scripts": {
    "start": "electron .",
    "server": "node marketing_server.js",
    "desktop": "electron . --disable-gpu"
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

Set-Content -Path $ServerPath -Value $serverJs -Encoding UTF8
Set-Content -Path $PackagePath -Value $package -Encoding UTF8
Set-Content -Path $LaunchPs1 -Value $launchPs1Content -Encoding UTF8
Set-Content -Path $LaunchBat -Value $launchBatContent -Encoding ASCII
Set-Content -Path $DesktopBat -Value $launchBatContent -Encoding ASCII

Set-Location $Suite
npm install | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH GPU + DESKTOP COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Music Agent collegato a: $AudioGpuSkill"
Write-Host "Video Agent collegato a: $VideoGpuSkill"
Write-Host "Launcher Desktop: $DesktopBat"
Write-Host ""
Write-Host 'Avvio:'
Write-Host '& "$HOME\Desktop\SuiteV17 Marketing Suite.bat"'