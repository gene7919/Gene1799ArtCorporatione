$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // CONTROL ROOM DESKTOP V2 " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$AppDir = Join-Path $Root "ElectronApp"

if (!(Test-Path $AppDir)) {
    New-Item -ItemType Directory -Force -Path $AppDir | Out-Null
}

$PackagePath = Join-Path $AppDir "package.json"
$MainPath    = Join-Path $AppDir "main.js"
$PreloadPath = Join-Path $AppDir "preload.js"
$IndexPath   = Join-Path $AppDir "index.html"
$LaunchPs1   = Join-Path $AppDir "Launch-ControlRoom.ps1"
$LaunchBat   = Join-Path $AppDir "Launch-ControlRoom.bat"
$DesktopBat  = Join-Path ([Environment]::GetFolderPath("Desktop")) "SuiteV17 Control Room.bat"

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
foreach ($f in @($PackagePath,$MainPath,$PreloadPath,$IndexPath,$LaunchPs1,$LaunchBat)) {
    if (Test-Path $f) {
        Copy-Item $f "$f.bak_$ts" -Force
    }
}

$packageJson = @'
{
  "name": "suitev17-control-room",
  "version": "2.0.0",
  "description": "Suite V17 Operator Control Room Desktop App",
  "main": "main.js",
  "scripts": {
    "start": "electron .",
    "desktop": "electron . --disable-gpu"
  },
  "devDependencies": {
    "electron": "^41.0.3"
  }
}
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
    width: 1720,
    height: 1020,
    minWidth: 1280,
    minHeight: 780,
    autoHideMenuBar: false,
    backgroundColor: "#050806",
    title: "Suite V17 // Operator Control Room",
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
const fs = require("fs");
const path = require("path");
const http = require("http");
const https = require("https");
const { exec } = require("child_process");

const ROOT = "C:\\SuiteV17";

const PATHS = {
  root: ROOT,
  tokenModule: path.join(ROOT, "TokenModule"),
  tokenData: path.join(ROOT, "TokenModule", "token_data.json"),
  tokenConfig: path.join(ROOT, "TokenModule", "config.json"),
  tokenLog: path.join(ROOT, "TokenModule", "token_monitor.log"),

  browserModule: path.join(ROOT, "BrowserModule"),
  browserServer: path.join(ROOT, "BrowserModule", "browser_server.js"),

  socialHub: path.join(ROOT, "SocialHubV1"),
  socialConfig: path.join(ROOT, "SocialHubV1", "config", "appsettings.json"),

  electronApp: path.join(ROOT, "ElectronApp")
};

function exists(p) {
  try { return fs.existsSync(p); } catch { return false; }
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

function tailLines(text, count = 80) {
  return String(text || "")
    .split(/\r?\n/)
    .filter(Boolean)
    .slice(-count);
}

function probeUrl(url, timeout = 3000) {
  return new Promise((resolve) => {
    try {
      const lib = url.startsWith("https") ? https : http;
      const req = lib.get(url, { timeout }, (res) => {
        resolve({
          ok: res.statusCode >= 200 && res.statusCode < 400,
          status: res.statusCode
        });
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

function psStart(scriptPath, workingDir) {
  const cmd = `powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process node -ArgumentList '${scriptPath}' -WorkingDirectory '${workingDir}'"`;
  return execPromise(cmd, workingDir);
}

async function getSystemSnapshot() {
  const tokenData = readJsonSafe(PATHS.tokenData, { status: "missing" });
  const tokenConfig = readJsonSafe(PATHS.tokenConfig, {});
  const socialConfig = readJsonSafe(PATHS.socialConfig, {});

  const browserHealth = await probeUrl("http://127.0.0.1:8093/health");
  const tokenDashHealth = await probeUrl("http://127.0.0.1:3018/health");

  return {
    now: new Date().toISOString(),
    paths: PATHS,
    modules: {
      token: {
        exists: exists(PATHS.tokenModule),
        data: tokenData,
        config: {
          telegramEnabled: !!tokenConfig.telegram?.enabled,
          socialEnabled: !!tokenConfig.social?.enabled,
          webhookConfigured: !!tokenConfig.social?.webhook,
          botConfigured: !!tokenConfig.telegram?.botToken,
          chatIdConfigured: !!tokenConfig.telegram?.chatId
        },
        dashboardHealth: tokenDashHealth
      },
      browser: {
        exists: exists(PATHS.browserModule),
        serverExists: exists(PATHS.browserServer),
        health: browserHealth
      },
      social: {
        exists: exists(PATHS.socialHub),
        configExists: exists(PATHS.socialConfig),
        config: {
          appName: socialConfig.app?.name || "",
          version: socialConfig.app?.version || "",
          autoPublish: socialConfig.publish?.autoPublish,
          requireApproval: socialConfig.publish?.requireApproval,
          platforms: socialConfig.publish?.defaultPlatforms || []
        }
      }
    },
    logs: {
      token: tailLines(readTextSafe(PATHS.tokenLog, ""), 80)
    }
  };
}

async function startTokenMonitor() {
  return psStart(".\\token_monitor.js", "C:\\SuiteV17\\TokenModule");
}

async function startTokenDashboardServer() {
  return psStart(".\\server.js", "C:\\SuiteV17\\TokenModule");
}

async function startBrowserModule() {
  if (!exists(PATHS.browserServer)) {
    return { ok: false, error: "browser_server.js non trovato" };
  }
  return psStart(".\\browser_server.js", "C:\\SuiteV17\\BrowserModule");
}

async function openBrowserHealth() {
  return shell.openExternal("http://127.0.0.1:8093/health");
}

async function openTokenDashboard() {
  return shell.openExternal("http://127.0.0.1:3018/");
}

async function testTelegram() {
  const cfg = readJsonSafe(PATHS.tokenConfig, {});
  const token = cfg.telegram?.botToken;
  const chatId = cfg.telegram?.chatId;

  if (!token || !chatId) {
    return { ok: false, error: "botToken o chatId mancanti in config.json" };
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
        try {
          const parsed = JSON.parse(body);
          resolve({ ok: !!parsed.ok, status: res.statusCode, data: parsed });
        } catch {
          resolve({ ok: false, status: res.statusCode, raw: body });
        }
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
    return { ok: false, error: "webhook mancante in config.json" };
  }

  const payload = JSON.stringify({
    platform: "telegram",
    title: "Suite V17 Control Room Test",
    source: "Electron Control Room",
    time: new Date().toISOString(),
    text: "✅ Webhook test da Suite V17 Control Room"
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
        res.on("end", () => {
          resolve({
            ok: res.statusCode >= 200 && res.statusCode < 300,
            status: res.statusCode,
            body
          });
        });
      });

      req.on("error", (err) => resolve({ ok: false, error: err.message }));
      req.write(payload);
      req.end();
    } catch (err) {
      resolve({ ok: false, error: err.message });
    }
  });
}

contextBridge.exposeInMainWorld("suitev17", {
  getSystemSnapshot,
  startTokenMonitor,
  startTokenDashboardServer,
  startBrowserModule,
  openBrowserHealth,
  openTokenDashboard,
  testTelegram,
  testWebhook,
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
  <title>Suite V17 // Operator Control Room</title>
  <style>
    :root{
      --bg:#050806;
      --panel:rgba(8,14,10,.94);
      --line:#8dff2a;
      --text:#dbff9d;
      --muted:#7faa56;
      --ok:#79ff93;
      --warn:#ffd15b;
      --bad:#ff6b6b;
    }
    *{box-sizing:border-box}
    body{
      margin:0;
      background:
        radial-gradient(circle at top, rgba(90,255,80,.06), transparent 35%),
        linear-gradient(180deg,#030503 0%,#081109 100%);
      color:var(--text);
      font-family:Consolas,"Courier New",monospace;
    }
    .wrap{max-width:1750px;margin:0 auto;padding:18px}
    .topbar,.panel{
      background:var(--panel);
      border:1px solid rgba(141,255,42,.2);
      border-radius:18px;
      box-shadow:0 0 20px rgba(141,255,42,.08);
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
      background:rgba(141,255,42,.08);
      border:1px solid rgba(141,255,42,.2);
      font-size:12px
    }
    .grid{display:grid;grid-template-columns:330px 1fr 430px;gap:16px}
    .panel{padding:16px}
    .stack{display:grid;gap:16px}
    h2{margin:0 0 14px;font-size:18px}
    .btn-grid{display:grid;gap:10px}
    button{
      width:100%;padding:11px 12px;border-radius:12px;
      border:1px solid rgba(141,255,42,.22);
      background:rgba(141,255,42,.08);
      color:var(--text);cursor:pointer;font-family:inherit
    }
    button:hover{background:rgba(141,255,42,.14)}
    .cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}
    .card,.service{
      background:rgba(0,0,0,.22);
      border:1px solid rgba(141,255,42,.14);
      border-radius:14px;padding:12px
    }
    .label{font-size:12px;color:var(--muted);margin-bottom:8px}
    .value{font-size:22px;word-break:break-word}
    .mini,.small{font-size:12px;color:var(--muted);word-break:break-word}
    .service-row{display:flex;justify-content:space-between;gap:10px;align-items:center}
    .dot{display:inline-block;width:10px;height:10px;border-radius:999px;margin-right:8px;vertical-align:middle}
    .ok{background:var(--ok);box-shadow:0 0 10px var(--ok)}
    .warn{background:var(--warn);box-shadow:0 0 10px var(--warn)}
    .bad{background:var(--bad);box-shadow:0 0 10px var(--bad)}
    .console,.logs{
      min-height:250px;max-height:460px;overflow:auto;white-space:pre-wrap;
      font-size:12px;line-height:1.45;background:rgba(0,0,0,.28);
      border:1px solid rgba(141,255,42,.12);border-radius:14px;padding:12px
    }
    .list{display:grid;gap:8px}
    @media (max-width:1280px){.grid{grid-template-columns:1fr}}
  </style>
</head>
<body>
<div class="wrap">
  <div class="topbar">
    <div>
      <div class="title">SUITE V17 // CONTROL ROOM</div>
      <div class="sub">App desktop operatore unificata</div>
    </div>
    <div class="badge" id="globalStatus">BOOT...</div>
  </div>

  <div class="grid">
    <div class="stack">
      <div class="panel">
        <h2>Quick Actions</h2>
        <div class="btn-grid">
          <button id="refreshBtn">Aggiorna stato</button>
          <button id="startTokenBtn">Avvia Token Monitor</button>
          <button id="startDashBtn">Avvia Token Dashboard</button>
          <button id="startBrowserBtn">Avvia BrowserModule</button>
          <button id="openTokenDashBtn">Apri Token Dashboard</button>
          <button id="openBrowserHealthBtn">Apri Browser Health</button>
          <button id="testTelegramBtn">Test Telegram</button>
          <button id="testWebhookBtn">Test Webhook</button>
          <button id="openTokenModuleBtn">Apri TokenModule</button>
          <button id="openBrowserModuleBtn">Apri BrowserModule</button>
          <button id="openSocialHubBtn">Apri SocialHubV1</button>
          <button id="openElectronAppBtn">Apri ElectronApp</button>
          <button id="openTokenConfigBtn">Apri config Token</button>
        </div>
      </div>

      <div class="panel">
        <h2>Servizi</h2>
        <div class="stack">
          <div class="service">
            <div class="service-row">
              <div><span class="dot" id="browserDot"></span>BrowserModule</div>
              <div class="small" id="browserStatus">...</div>
            </div>
            <div class="mini" id="browserMeta">Porta 8093</div>
          </div>
          <div class="service">
            <div class="service-row">
              <div><span class="dot" id="tokenDashDot"></span>Token Dashboard</div>
              <div class="small" id="tokenDashStatus">...</div>
            </div>
            <div class="mini" id="tokenDashMeta">Porta 3018</div>
          </div>
          <div class="service">
            <div class="service-row">
              <div><span class="dot" id="telegramDot"></span>Telegram</div>
              <div class="small" id="telegramStatus">...</div>
            </div>
            <div class="mini" id="telegramMeta">Bot e Chat</div>
          </div>
          <div class="service">
            <div class="service-row">
              <div><span class="dot" id="socialDot"></span>SocialHub / Webhook</div>
              <div class="small" id="socialStatus">...</div>
            </div>
            <div class="mini" id="socialMeta">Make / n8n / autopost</div>
          </div>
        </div>
      </div>
    </div>

    <div class="stack">
      <div class="panel">
        <h2>GENE1799 Live</h2>
        <div class="cards">
          <div class="card"><div class="label">STATUS</div><div class="value" id="tokenStatus">-</div></div>
          <div class="card"><div class="label">PRICE</div><div class="value" id="tokenPrice">-</div></div>
          <div class="card"><div class="label">LIQUIDITY</div><div class="value" id="tokenLiquidity">-</div></div>
          <div class="card"><div class="label">VOLUME 24H</div><div class="value" id="tokenVolume">-</div></div>
          <div class="card"><div class="label">FDV</div><div class="value" id="tokenFdv">-</div></div>
          <div class="card"><div class="label">DEX</div><div class="value" id="tokenDex">-</div></div>
        </div>
        <div class="mini" style="margin-top:12px;">Pair: <span id="tokenPair">-</span></div>
        <div class="mini">Update: <span id="tokenUpdate">-</span></div>
        <div class="mini">TXNS: <span id="tokenTxns">-</span></div>
      </div>

      <div class="panel">
        <h2>SocialHubV1</h2>
        <div class="list small">
          <div>App: <span id="socialApp">-</span></div>
          <div>Versione: <span id="socialVersion">-</span></div>
          <div>Auto publish: <span id="socialAuto">-</span></div>
          <div>Require approval: <span id="socialApproval">-</span></div>
          <div>Platforms: <span id="socialPlatforms">-</span></div>
        </div>
      </div>

      <div class="panel">
        <h2>Operator Console</h2>
        <div class="console" id="consoleBox">Console pronta.</div>
      </div>
    </div>

    <div class="stack">
      <div class="panel">
        <h2>Token Logs</h2>
        <div class="logs" id="tokenLogs">Caricamento log...</div>
      </div>

      <div class="panel">
        <h2>Percorsi Moduli</h2>
        <div class="list small">
          <div>TokenModule: <span id="pathToken">-</span></div>
          <div>BrowserModule: <span id="pathBrowser">-</span></div>
          <div>SocialHubV1: <span id="pathSocial">-</span></div>
          <div>ElectronApp: <span id="pathElectron">-</span></div>
        </div>
      </div>
    </div>
  </div>
</div>

<script>
const ui = {
  globalStatus: document.getElementById("globalStatus"),
  tokenStatus: document.getElementById("tokenStatus"),
  tokenPrice: document.getElementById("tokenPrice"),
  tokenLiquidity: document.getElementById("tokenLiquidity"),
  tokenVolume: document.getElementById("tokenVolume"),
  tokenFdv: document.getElementById("tokenFdv"),
  tokenDex: document.getElementById("tokenDex"),
  tokenPair: document.getElementById("tokenPair"),
  tokenUpdate: document.getElementById("tokenUpdate"),
  tokenTxns: document.getElementById("tokenTxns"),
  tokenLogs: document.getElementById("tokenLogs"),
  consoleBox: document.getElementById("consoleBox"),

  browserDot: document.getElementById("browserDot"),
  browserStatus: document.getElementById("browserStatus"),
  browserMeta: document.getElementById("browserMeta"),
  tokenDashDot: document.getElementById("tokenDashDot"),
  tokenDashStatus: document.getElementById("tokenDashStatus"),
  tokenDashMeta: document.getElementById("tokenDashMeta"),
  telegramDot: document.getElementById("telegramDot"),
  telegramStatus: document.getElementById("telegramStatus"),
  telegramMeta: document.getElementById("telegramMeta"),
  socialDot: document.getElementById("socialDot"),
  socialStatus: document.getElementById("socialStatus"),
  socialMeta: document.getElementById("socialMeta"),

  socialApp: document.getElementById("socialApp"),
  socialVersion: document.getElementById("socialVersion"),
  socialAuto: document.getElementById("socialAuto"),
  socialApproval: document.getElementById("socialApproval"),
  socialPlatforms: document.getElementById("socialPlatforms"),

  pathToken: document.getElementById("pathToken"),
  pathBrowser: document.getElementById("pathBrowser"),
  pathSocial: document.getElementById("pathSocial"),
  pathElectron: document.getElementById("pathElectron")
};

function log(msg){
  const line = `[${new Date().toLocaleTimeString()}] ${msg}`;
  ui.consoleBox.textContent = `${line}\n` + ui.consoleBox.textContent;
}

function dot(el, mode){
  el.className = "dot " + mode;
}

function money(v){
  if (v === null || typeof v === "undefined" || v === "") return "-";
  return "$" + v;
}

async function refresh(){
  try{
    const snap = await window.suitev17.getSystemSnapshot();
    ui.globalStatus.textContent = `ONLINE // ${snap.now}`;

    const token = snap.modules.token.data || {};
    ui.tokenStatus.textContent = token.status ?? "-";
    ui.tokenPrice.textContent = money(token.price);
    ui.tokenLiquidity.textContent = money(token.liquidity);
    ui.tokenVolume.textContent = money(token.volume24h);
    ui.tokenFdv.textContent = money(token.fdv);
    ui.tokenDex.textContent = token.dexId ?? "-";
    ui.tokenPair.textContent = token.pairAddress ?? "-";
    ui.tokenUpdate.textContent = token.lastUpdate ?? "-";
    ui.tokenTxns.textContent = token.txns ? JSON.stringify(token.txns) : "-";

    ui.tokenLogs.textContent = (snap.logs.token || []).join("\n") || "Nessun log";

    ui.pathToken.textContent = snap.paths.tokenModule;
    ui.pathBrowser.textContent = snap.paths.browserModule;
    ui.pathSocial.textContent = snap.paths.socialHub;
    ui.pathElectron.textContent = snap.paths.electronApp;

    if (snap.modules.browser.health?.ok){
      dot(ui.browserDot, "ok");
      ui.browserStatus.textContent = "online";
      ui.browserMeta.textContent = `Health OK (${snap.modules.browser.health.status})`;
    } else {
      dot(ui.browserDot, "bad");
      ui.browserStatus.textContent = "offline";
      ui.browserMeta.textContent = snap.modules.browser.health?.error || "nessuna risposta";
    }

    if (snap.modules.token.dashboardHealth?.ok){
      dot(ui.tokenDashDot, "ok");
      ui.tokenDashStatus.textContent = "online";
      ui.tokenDashMeta.textContent = `Health OK (${snap.modules.token.dashboardHealth.status})`;
    } else {
      dot(ui.tokenDashDot, "warn");
      ui.tokenDashStatus.textContent = "non attivo";
      ui.tokenDashMeta.textContent = snap.modules.token.dashboardHealth?.error || "server non risponde";
    }

    if (snap.modules.token.config?.telegramEnabled && snap.modules.token.config?.botConfigured && snap.modules.token.config?.chatIdConfigured){
      dot(ui.telegramDot, "ok");
      ui.telegramStatus.textContent = "configurato";
      ui.telegramMeta.textContent = "bot + chatId presenti";
    } else {
      dot(ui.telegramDot, "warn");
      ui.telegramStatus.textContent = "parziale";
      ui.telegramMeta.textContent = "controlla config.json";
    }

    if (snap.modules.token.config?.socialEnabled && snap.modules.token.config?.webhookConfigured){
      dot(ui.socialDot, "ok");
      ui.socialStatus.textContent = "configurato";
      ui.socialMeta.textContent = "webhook presente";
    } else {
      dot(ui.socialDot, "warn");
      ui.socialStatus.textContent = "parziale";
      ui.socialMeta.textContent = "webhook non completo";
    }

    const social = snap.modules.social.config || {};
    ui.socialApp.textContent = social.appName || "-";
    ui.socialVersion.textContent = social.version || "-";
    ui.socialAuto.textContent = typeof social.autoPublish === "boolean" ? social.autoPublish : "-";
    ui.socialApproval.textContent = typeof social.requireApproval === "boolean" ? social.requireApproval : "-";
    ui.socialPlatforms.textContent = Array.isArray(social.platforms) ? social.platforms.join(", ") : "-";

    log("Snapshot aggiornato");
  } catch(err){
    ui.globalStatus.textContent = "ERRORE SNAPSHOT";
    log("Errore refresh: " + err.message);
  }
}

document.getElementById("refreshBtn").addEventListener("click", refresh);

document.getElementById("startTokenBtn").addEventListener("click", async () => {
  log("Avvio Token Monitor...");
  log(JSON.stringify(await window.suitev17.startTokenMonitor()));
  setTimeout(refresh, 1500);
});

document.getElementById("startDashBtn").addEventListener("click", async () => {
  log("Avvio Token Dashboard...");
  log(JSON.stringify(await window.suitev17.startTokenDashboardServer()));
  setTimeout(refresh, 1500);
});

document.getElementById("startBrowserBtn").addEventListener("click", async () => {
  log("Avvio BrowserModule...");
  log(JSON.stringify(await window.suitev17.startBrowserModule()));
  setTimeout(refresh, 2000);
});

document.getElementById("openTokenDashBtn").addEventListener("click", () => window.suitev17.openTokenDashboard());
document.getElementById("openBrowserHealthBtn").addEventListener("click", () => window.suitev17.openBrowserHealth());

document.getElementById("testTelegramBtn").addEventListener("click", async () => {
  log("Test Telegram...");
  log(JSON.stringify(await window.suitev17.testTelegram()));
});

document.getElementById("testWebhookBtn").addEventListener("click", async () => {
  log("Test Webhook...");
  log(JSON.stringify(await window.suitev17.testWebhook()));
});

document.getElementById("openTokenModuleBtn").addEventListener("click", () => window.suitev17.openPath("C:\\SuiteV17\\TokenModule"));
document.getElementById("openBrowserModuleBtn").addEventListener("click", () => window.suitev17.openPath("C:\\SuiteV17\\BrowserModule"));
document.getElementById("openSocialHubBtn").addEventListener("click", () => window.suitev17.openPath("C:\\SuiteV17\\SocialHubV1"));
document.getElementById("openElectronAppBtn").addEventListener("click", () => window.suitev17.openPath("C:\\SuiteV17\\ElectronApp"));
document.getElementById("openTokenConfigBtn").addEventListener("click", () => window.suitev17.openPath("C:\\SuiteV17\\TokenModule\\config.json"));

refresh();
setInterval(refresh, 10000);
</script>
</body>
</html>
'@

$launchPs1Content = @'
$ErrorActionPreference = "Stop"
Set-Location "C:\SuiteV17\ElectronApp"

if (!(Test-Path ".\UserData")) {
    New-Item -ItemType Directory -Force -Path ".\UserData" | Out-Null
}

$env:ELECTRON_USER_DATA_DIR = "C:\SuiteV17\ElectronApp\UserData"
$env:ELECTRON_DISABLE_GPU   = "1"

npm start -- --disable-gpu
'@

$launchBatContent = @'
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\SuiteV17\ElectronApp\Launch-ControlRoom.ps1"
'@

Set-Content -Path $PackagePath -Value $packageJson -Encoding UTF8
Set-Content -Path $MainPath -Value $mainJs -Encoding UTF8
Set-Content -Path $PreloadPath -Value $preloadJs -Encoding UTF8
Set-Content -Path $IndexPath -Value $indexHtml -Encoding UTF8
Set-Content -Path $LaunchPs1 -Value $launchPs1Content -Encoding UTF8
Set-Content -Path $LaunchBat -Value $launchBatContent -Encoding ASCII
Set-Content -Path $DesktopBat -Value $launchBatContent -Encoding ASCII

Write-Host "File Control Room V2 creati." -ForegroundColor Green

Set-Location $AppDir

if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
    throw "npm non trovato nel PATH."
}

Write-Host "Installazione dipendenze Electron..." -ForegroundColor Cyan
npm install | Out-Host

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PATCH CONTROL ROOM DESKTOP V2 COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "App: C:\SuiteV17\ElectronApp"
Write-Host "Launcher locale: C:\SuiteV17\ElectronApp\Launch-ControlRoom.bat"
Write-Host "Launcher Desktop: $DesktopBat"
Write-Host ""
Write-Host "Avvio rapido:"
Write-Host " - doppio click su 'SuiteV17 Control Room.bat' dal Desktop"
Write-Host " - oppure esegui C:\SuiteV17\ElectronApp\Launch-ControlRoom.bat"