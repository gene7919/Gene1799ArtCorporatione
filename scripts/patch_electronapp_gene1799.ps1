$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 // ELECTRONAPP GENE1799 PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$AppDir       = "C:\SuiteV17\ElectronApp"
$MainPath     = Join-Path $AppDir "main.js"
$PreloadPath  = Join-Path $AppDir "preload.js"
$IndexPath    = Join-Path $AppDir "index.html"
$TokenData    = "C:\SuiteV17\TokenModule\token_data.json"

foreach ($p in @($MainPath,$PreloadPath,$IndexPath)) {
    if (!(Test-Path $p)) { throw "File non trovato: $p" }
}

if (!(Test-Path $TokenData)) {
    throw "token_data.json non trovato: $TokenData"
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"
Copy-Item $MainPath    "$MainPath.bak_$ts"    -Force
Copy-Item $PreloadPath "$PreloadPath.bak_$ts" -Force
Copy-Item $IndexPath   "$IndexPath.bak_$ts"   -Force

Write-Host "Backup creati." -ForegroundColor Green

# -----------------------------
# PATCH PRELOAD
# -----------------------------
$preload = Get-Content $PreloadPath -Raw

if ($preload -notmatch "GENE1799_PRELOAD_BRIDGE") {
    $bridge = @'

/* GENE1799_PRELOAD_BRIDGE_START */
const { contextBridge } = require("electron");
const fs = require("fs");
const path = require("path");

function readGene1799TokenData() {
  try {
    const tokenFile = "C:\\SuiteV17\\TokenModule\\token_data.json";
    const raw = fs.readFileSync(tokenFile, "utf8");
    return JSON.parse(raw);
  } catch (err) {
    return {
      status: "error",
      error: err.message,
      lastUpdate: new Date().toISOString()
    };
  }
}

try {
  contextBridge.exposeInMainWorld("gene1799API", {
    getTokenData: () => readGene1799TokenData()
  });
} catch (e) {
  // fallback se contextBridge è già usato altrove
  global.gene1799API = {
    getTokenData: () => readGene1799TokenData()
  };
}
/* GENE1799_PRELOAD_BRIDGE_END */
'@
    Add-Content -Path $PreloadPath -Value $bridge -Encoding UTF8
    Write-Host "preload.js patchato." -ForegroundColor Green
} else {
    Write-Host "preload.js già patchato." -ForegroundColor Yellow
}

# -----------------------------
# PATCH INDEX
# -----------------------------
$index = Get-Content $IndexPath -Raw

if ($index -notmatch "GENE1799_WIDGET_ELECTRON_START") {

$widget = @'
<!-- GENE1799_WIDGET_ELECTRON_START -->
<section id="gene1799-widget" style="
  margin:18px;
  padding:18px;
  border:1px solid #99ff00;
  border-radius:16px;
  background:rgba(0,0,0,0.72);
  color:#d8ff57;
  font-family:Consolas, monospace;
  box-shadow:0 0 20px rgba(153,255,0,0.15);
">
  <div style="font-size:24px;font-weight:700;margin-bottom:14px;">
    GENE1799 // LIVE TOKEN PANEL
  </div>

  <div style="
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(180px,1fr));
    gap:12px;
  ">
    <div><div style="opacity:.7">STATUS</div><div id="g1799-status">...</div></div>
    <div><div style="opacity:.7">PRICE</div><div id="g1799-price">...</div></div>
    <div><div style="opacity:.7">LIQUIDITY</div><div id="g1799-liquidity">...</div></div>
    <div><div style="opacity:.7">VOLUME 24H</div><div id="g1799-volume">...</div></div>
    <div><div style="opacity:.7">FDV</div><div id="g1799-fdv">...</div></div>
    <div><div style="opacity:.7">DEX</div><div id="g1799-dex">...</div></div>
  </div>

  <div style="margin-top:12px;font-size:12px;opacity:.8;word-break:break-all;">
    Pair: <span id="g1799-pair">...</span>
  </div>
  <div style="margin-top:6px;font-size:12px;opacity:.8;">
    Update: <span id="g1799-update">...</span>
  </div>
  <div style="margin-top:6px;font-size:12px;opacity:.8;">
    TXNS: <span id="g1799-txns">...</span>
  </div>
</section>

<script>
(function () {
  function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function renderGene1799(data) {
    setText("g1799-status", data?.status ?? "-");
    setText("g1799-price", data?.price != null ? "$" + data.price : "-");
    setText("g1799-liquidity", data?.liquidity != null ? "$" + data.liquidity : "-");
    setText("g1799-volume", data?.volume24h != null ? "$" + data.volume24h : "-");
    setText("g1799-fdv", data?.fdv != null ? "$" + data.fdv : "-");
    setText("g1799-dex", data?.dexId ?? "-");
    setText("g1799-pair", data?.pairAddress ?? "-");
    setText("g1799-update", data?.lastUpdate ?? "-");
    setText("g1799-txns", data?.txns ? JSON.stringify(data.txns) : "-");
  }

  function loadGene1799() {
    try {
      const api = window.gene1799API || globalThis.gene1799API;
      if (!api || typeof api.getTokenData !== "function") {
        renderGene1799({ status: "bridge_missing" });
        return;
      }
      const data = api.getTokenData();
      renderGene1799(data);
    } catch (err) {
      renderGene1799({ status: "ui_error", pairAddress: err.message });
    }
  }

  function bootGene1799() {
    loadGene1799();
    setInterval(loadGene1799, 5000);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", bootGene1799);
  } else {
    bootGene1799();
  }
})();
</script>
<!-- GENE1799_WIDGET_ELECTRON_END -->
'@

    if ($index -match "</body>") {
        $index = $index -replace "</body>", ($widget + "`r`n</body>")
    } else {
        $index += "`r`n" + $widget
    }

    Set-Content -Path $IndexPath -Value $index -Encoding UTF8
    Write-Host "index.html patchato." -ForegroundColor Green
} else {
    Write-Host "index.html già patchato." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PATCH COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Target: $AppDir"
Write-Host "Backup timestamp: $ts"
Write-Host ""
Write-Host "Adesso riavvia ElectronApp."