$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // GENSTUDIOAPP + OPSCONTROLAPP " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"

# -------------------------
# PATHS
# -------------------------
$GenApp = Join-Path $Root "GenStudioApp"
$OpsApp = Join-Path $Root "OpsControlApp"

$GenDesktopBat = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 GenStudioApp.bat"
$OpsDesktopBat = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 OpsControlApp.bat"

foreach ($dir in @($GenApp, $OpsApp)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# -------------------------
# COMMON FILE WRITER
# -------------------------
function Write-Utf8File {
    param([string]$Path, [string]$Content)
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

# -------------------------
# GENSTUDIOAPP
# -------------------------
$genPackage = @'
{
  "name": "suitev17-genstudioapp",
  "version": "1.0.0",
  "main": "main.js",
  "scripts": {
    "start": "electron ."
  },
  "devDependencies": {
    "electron": "^41.0.3"
  }
}
'@

$genMain = @'
const { app, BrowserWindow, shell } = require("electron");
const path = require("path");
const fs = require("fs");

function ensureDir(dir) {
  try { fs.mkdirSync(dir, { recursive: true }); } catch {}
}

app.commandLine.appendSwitch("disable-gpu");
app.commandLine.appendSwitch("disable-software-rasterizer");

function createWindow() {
  ensureDir(path.join(__dirname, "UserData"));

  const win = new BrowserWindow({
    width: 1600,
    height: 980,
    minWidth: 1200,
    minHeight: 760,
    backgroundColor: "#0b0d14",
    title: "Suite V17 // GenStudioApp",
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

app.whenReady().then(createWindow);
app.on("window-all-closed", () => { if (process.platform !== "darwin") app.quit(); });
'@

$genPreload = @'
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
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
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
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    });

    req.on("error", reject);
    req.write(payload);
    req.end();
  });
}

function startProcess(script, cwd) {
  return new Promise((resolve) => {
    const cmd = `Start-Process node -ArgumentList '${script}' -WorkingDirectory '${cwd}'`;
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

contextBridge.exposeInMainWorld("genStudioApp", {
  startAIHub: () => startProcess(".\\ollama_router.js", "C:\\SuiteV17\\AIHub"),
  startGenStudio: () => startProcess(".\\genstudio_server.js", "C:\\SuiteV17\\GenStudio"),
  healthAIHub: () => getJson("http://127.0.0.1:3020/health"),
  healthGenStudio: () => getJson("http://127.0.0.1:3021/health"),
  jobs: () => getJson("http://127.0.0.1:3021/api/jobs"),
  logs: () => getJson("http://127.0.0.1:3021/api/logs"),
  genText: (prompt, model) => postJson("http://127.0.0.1:3021/api/generate/text", { prompt, model }),
  genAudio: (prompt, duration, style) => postJson("http://127.0.0.1:3021/api/generate/audio", { prompt, duration, style }),
  genVideo: (prompt, duration, fps, resolution) => postJson("http://127.0.0.1:3021/api/generate/video", { prompt, duration, fps, resolution }),
  openPath: (target) => shell.openPath(target)
});
'@

$genIndex = @'
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>GenStudioApp</title>
<style>
body{margin:0;font-family:Consolas;background:#0b0d14;color:#e7ecff}
.wrap{max-width:1700px;margin:0 auto;padding:18px}
.grid{display:grid;grid-template-columns:340px 1fr 420px;gap:16px}
.panel{background:#121726;border:1px solid #334;padding:16px;border-radius:16px}
textarea,input,select,button{width:100%;box-sizing:border-box;padding:10px;border-radius:10px;margin:6px 0;background:#0e1220;color:#fff;border:1px solid #334;font-family:inherit}
button{cursor:pointer}
.box{white-space:pre-wrap;max-height:420px;overflow:auto;background:#0a0e1b;padding:12px;border-radius:12px;border:1px solid #334}
@media (max-width:1280px){.grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="wrap">
  <h1>Suite V17 // GenStudioApp</h1>
  <div class="grid">
    <div class="panel">
      <h3>Avvio</h3>
      <button id="startAIHub">Avvia AIHub</button>
      <button id="startGenStudio">Avvia GenStudio</button>
      <button id="refresh">Aggiorna</button>
      <button id="openText">Apri output text</button>
      <button id="openAudio">Apri output audio</button>
      <button id="openVideo">Apri output video</button>
      <div class="box" id="statusBox">BOOT...</div>
    </div>

    <div class="panel">
      <h3>Agenti e orchestratori creativi</h3>

      <h4>Text Agent</h4>
      <select id="textModel">
        <option value="qwen3:4b">qwen3:4b</option>
        <option value="qwen3:8b">qwen3:8b</option>
      </select>
      <textarea id="textPrompt" placeholder="Prompt testo marketing o creativo"></textarea>
      <button id="runText">Genera testo</button>

      <h4>Music Orchestrator</h4>
      <input id="audioPrompt" placeholder="Prompt musicale" />
      <input id="audioDuration" type="number" value="8" />
      <input id="audioStyle" value="cinematic" />
      <button id="runAudio">Prepara audio</button>

      <h4>Video Coordinator</h4>
      <input id="videoPrompt" placeholder="Prompt video" />
      <input id="videoDuration" type="number" value="4" />
      <input id="videoFps" type="number" value="24" />
      <select id="videoResolution">
        <option value="1920x1080">1920x1080</option>
        <option value="2560x1440">2560x1440</option>
        <option value="3840x2160">3840x2160 (4K)</option>
      </select>
      <button id="runVideo">Prepara video</button>

      <div class="box" id="outputBox">Nessun output.</div>
    </div>

    <div class="panel">
      <h3>Jobs / Logs</h3>
      <div class="box" id="jobsBox">Jobs...</div>
      <br/>
      <div class="box" id="logsBox">Logs...</div>
    </div>
  </div>
</div>

<script>
const statusBox = document.getElementById("statusBox");
const jobsBox = document.getElementById("jobsBox");
const logsBox = document.getElementById("logsBox");
const outputBox = document.getElementById("outputBox");

async function refresh() {
  try {
    const a = await window.genStudioApp.healthAIHub();
    const g = await window.genStudioApp.healthGenStudio();
    const j = await window.genStudioApp.jobs();
    const l = await window.genStudioApp.logs();
    statusBox.textContent = JSON.stringify({ aihub: a, genstudio: g }, null, 2);
    jobsBox.textContent = JSON.stringify(j, null, 2);
    logsBox.textContent = JSON.stringify(l, null, 2);
  } catch (e) {
    statusBox.textContent = e.message;
  }
}

document.getElementById("startAIHub").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.genStudioApp.startAIHub(), null, 2);
document.getElementById("startGenStudio").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.genStudioApp.startGenStudio(), null, 2);
document.getElementById("refresh").onclick = refresh;
document.getElementById("openText").onclick = ()=> window.genStudioApp.openPath("C:\\SuiteV17\\GenStudio\\output\\text");
document.getElementById("openAudio").onclick = ()=> window.genStudioApp.openPath("C:\\SuiteV17\\GenStudio\\output\\audio");
document.getElementById("openVideo").onclick = ()=> window.genStudioApp.openPath("C:\\SuiteV17\\GenStudio\\output\\video");

document.getElementById("runText").onclick = async ()=>{
  const prompt = document.getElementById("textPrompt").value.trim();
  const model = document.getElementById("textModel").value;
  outputBox.textContent = JSON.stringify(await window.genStudioApp.genText(prompt, model), null, 2);
  refresh();
};

document.getElementById("runAudio").onclick = async ()=>{
  const prompt = document.getElementById("audioPrompt").value.trim();
  const duration = Number(document.getElementById("audioDuration").value || 8);
  const style = document.getElementById("audioStyle").value.trim();
  outputBox.textContent = JSON.stringify(await window.genStudioApp.genAudio(prompt, duration, style), null, 2);
  refresh();
};

document.getElementById("runVideo").onclick = async ()=>{
  const prompt = document.getElementById("videoPrompt").value.trim();
  const duration = Number(document.getElementById("videoDuration").value || 4);
  const fps = Number(document.getElementById("videoFps").value || 24);
  const resolution = document.getElementById("videoResolution").value;
  outputBox.textContent = JSON.stringify(await window.genStudioApp.genVideo(prompt, duration, fps, resolution), null, 2);
  refresh();
};

refresh();
setInterval(refresh, 10000);
</script>
</body>
</html>
'@

$genLaunchPs1 = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\GenStudioApp"
if (!(Test-Path ".\UserData")) { New-Item -ItemType Directory -Force -Path ".\UserData" | Out-Null }
$env:ELECTRON_USER_DATA_DIR = "C:\SuiteV17\GenStudioApp\UserData"
$env:ELECTRON_DISABLE_GPU = "1"
npm start -- --disable-gpu
'@

$genLaunchBat = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\GenStudioApp\Launch-GenStudioApp.ps1"
'@

Write-Utf8File (Join-Path $GenApp "package.json") $genPackage
Write-Utf8File (Join-Path $GenApp "main.js") $genMain
Write-Utf8File (Join-Path $GenApp "preload.js") $genPreload
Write-Utf8File (Join-Path $GenApp "index.html") $genIndex
Write-Utf8File (Join-Path $GenApp "Launch-GenStudioApp.ps1") $genLaunchPs1
Set-Content (Join-Path $GenApp "Launch-GenStudioApp.bat") $genLaunchBat -Encoding Ascii
Set-Content $GenDesktopBat $genLaunchBat -Encoding Ascii

# -------------------------
# OPSCONTROLAPP
# -------------------------
$opsPackage = @'
{
  "name": "suitev17-opscontrolapp",
  "version": "1.0.0",
  "main": "main.js",
  "scripts": {
    "start": "electron ."
  },
  "devDependencies": {
    "electron": "^41.0.3"
  }
}
'@

$opsMain = $genMain.Replace("GenStudioApp","OpsControlApp")

$opsPreload = @'
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
        try { resolve(JSON.parse(data)); } catch (e) { reject(e); }
      });
    });
    req.on("error", reject);
  });
}

function postTelegramTest() {
  return new Promise((resolve, reject) => {
    getJson("http://127.0.0.1:3020/health").then(resolve).catch(reject);
  });
}

function startNode(script, cwd) {
  return new Promise((resolve) => {
    const cmd = `Start-Process node -ArgumentList '${script}' -WorkingDirectory '${cwd}'`;
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

contextBridge.exposeInMainWorld("opsControlApp", {
  startAIHub: () => startNode(".\\ollama_router.js", "C:\\SuiteV17\\AIHub"),
  startTokenMonitor: () => startNode(".\\token_monitor.js", "C:\\SuiteV17\\TokenModule"),
  startTokenDash: () => startNode(".\\server.js", "C:\\SuiteV17\\TokenModule"),
  startBrowserModule: () => startNode(".\\browser_server.js", "C:\\SuiteV17\\BrowserModule"),
  healthAIHub: () => getJson("http://127.0.0.1:3020/health"),
  tokenDashHealth: () => getJson("http://127.0.0.1:3018/health"),
  browserHealth: () => getJson("http://127.0.0.1:8093/health"),
  openPath: (target) => shell.openPath(target),
  openExternal: (url) => shell.openExternal(url)
});
'@

$opsIndex = @'
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>OpsControlApp</title>
<style>
body{margin:0;font-family:Consolas;background:#07100a;color:#e9ffef}
.wrap{max-width:1700px;margin:0 auto;padding:18px}
.grid{display:grid;grid-template-columns:360px 1fr 420px;gap:16px}
.panel{background:#0f1b13;border:1px solid #294034;padding:16px;border-radius:16px}
button{width:100%;padding:10px;border-radius:10px;margin:6px 0;background:#102417;color:#fff;border:1px solid #294034;cursor:pointer;font-family:inherit}
.box{white-space:pre-wrap;max-height:520px;overflow:auto;background:#0a140d;padding:12px;border-radius:12px;border:1px solid #294034}
@media (max-width:1280px){.grid{grid-template-columns:1fr}}
</style>
</head>
<body>
<div class="wrap">
  <h1>Suite V17 // OpsControlApp</h1>
  <div class="grid">
    <div class="panel">
      <h3>Servizi operativi</h3>
      <button id="startAIHub">Avvia AIHub</button>
      <button id="startTokenMonitor">Avvia Token Monitor</button>
      <button id="startTokenDash">Avvia Token Dashboard</button>
      <button id="startBrowser">Avvia BrowserModule</button>
      <button id="refresh">Aggiorna</button>
      <button id="openToken">Apri TokenModule</button>
      <button id="openBrowser">Apri BrowserModule</button>
      <button id="openSocial">Apri SocialHubV1</button>
      <button id="openMake">Apri Make</button>
    </div>

    <div class="panel">
      <h3>Analisi token / health / Make</h3>
      <div class="box" id="statusBox">BOOT...</div>
    </div>

    <div class="panel">
      <h3>Console</h3>
      <div class="box" id="outputBox">Nessun output.</div>
    </div>
  </div>
</div>

<script>
const statusBox = document.getElementById("statusBox");
const outputBox = document.getElementById("outputBox");

async function safe(fn) {
  try { return await fn(); } catch (e) { return { ok:false, error:e.message }; }
}

async function refresh() {
  const a = await safe(()=>window.opsControlApp.healthAIHub());
  const t = await safe(()=>window.opsControlApp.tokenDashHealth());
  const b = await safe(()=>window.opsControlApp.browserHealth());
  statusBox.textContent = JSON.stringify({ aihub:a, tokenDash:t, browser:b }, null, 2);
}

document.getElementById("startAIHub").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.opsControlApp.startAIHub(), null, 2);
document.getElementById("startTokenMonitor").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.opsControlApp.startTokenMonitor(), null, 2);
document.getElementById("startTokenDash").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.opsControlApp.startTokenDash(), null, 2);
document.getElementById("startBrowser").onclick = async ()=> outputBox.textContent = JSON.stringify(await window.opsControlApp.startBrowserModule(), null, 2);
document.getElementById("refresh").onclick = refresh;
document.getElementById("openToken").onclick = ()=> window.opsControlApp.openPath("C:\\SuiteV17\\TokenModule");
document.getElementById("openBrowser").onclick = ()=> window.opsControlApp.openPath("C:\\SuiteV17\\BrowserModule");
document.getElementById("openSocial").onclick = ()=> window.opsControlApp.openPath("C:\\SuiteV17\\SocialHubV1");
document.getElementById("openMake").onclick = ()=> window.opsControlApp.openExternal("https://www.make.com");

refresh();
setInterval(refresh, 10000);
</script>
</body>
</html>
'@

$opsLaunchPs1 = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\OpsControlApp"
if (!(Test-Path ".\UserData")) { New-Item -ItemType Directory -Force -Path ".\UserData" | Out-Null }
$env:ELECTRON_USER_DATA_DIR = "C:\SuiteV17\OpsControlApp\UserData"
$env:ELECTRON_DISABLE_GPU = "1"
npm start -- --disable-gpu
'@

$opsLaunchBat = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\OpsControlApp\Launch-OpsControlApp.ps1"
'@

Write-Utf8File (Join-Path $OpsApp "package.json") $opsPackage
Write-Utf8File (Join-Path $OpsApp "main.js") $opsMain
Write-Utf8File (Join-Path $OpsApp "preload.js") $opsPreload
Write-Utf8File (Join-Path $OpsApp "index.html") $opsIndex
Write-Utf8File (Join-Path $OpsApp "Launch-OpsControlApp.ps1") $opsLaunchPs1
Set-Content (Join-Path $OpsApp "Launch-OpsControlApp.bat") $opsLaunchBat -Encoding Ascii
Set-Content $OpsDesktopBat $opsLaunchBat -Encoding Ascii

# -------------------------
# INSTALL
# -------------------------
Set-Location $GenApp
npm install | Out-Host
Set-Location $OpsApp
npm install | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "GenStudioApp: C:\SuiteV17\GenStudioApp"
Write-Host "OpsControlApp: C:\SuiteV17\OpsControlApp"
Write-Host "Desktop launchers creati:"
Write-Host " - $GenDesktopBat"
Write-Host " - $OpsDesktopBat"
Write-Host ""
Write-Host 'Avvio GenStudioApp: & "$HOME\Desktop\SuiteV17 GenStudioApp.bat"'
Write-Host 'Avvio OpsControlApp: & "$HOME\Desktop\SuiteV17 OpsControlApp.bat"'