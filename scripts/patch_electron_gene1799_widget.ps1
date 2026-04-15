$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SUITE V17 - ELECTRON GENE1799 WIDGET " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$TokenModule = Join-Path $Root "TokenModule"
$TokenData = Join-Path $TokenModule "token_data.json"

if (!(Test-Path $TokenModule)) {
    throw "TokenModule non trovato in C:\SuiteV17\TokenModule"
}

if (!(Test-Path $TokenData)) {
    throw "token_data.json non trovato in $TokenData"
}

# Cerca file HTML candidati della dashboard Electron
$HtmlCandidates = Get-ChildItem -Path $Root -Recurse -File -Include *.html |
    Where-Object {
        $_.FullName -notmatch "node_modules|dist|out|build|coverage|\.git"
    }

Write-Host ""
Write-Host "HTML trovati:" -ForegroundColor Yellow
$index = 0
$HtmlCandidates | ForEach-Object {
    Write-Host "[$index] $($_.FullName)"
    $index++
}

if ($HtmlCandidates.Count -eq 0) {
    throw "Nessun file HTML trovato nella Suite."
}

$choice = Read-Host "Inserisci il numero del file HTML Electron da patchare"
if ($choice -notmatch '^\d+$') {
    throw "Scelta non valida."
}
$choice = [int]$choice

if ($choice -lt 0 -or $choice -ge $HtmlCandidates.Count) {
    throw "Indice fuori range."
}

$TargetHtml = $HtmlCandidates[$choice].FullName
Write-Host ""
Write-Host "Target selezionato: $TargetHtml" -ForegroundColor Green

# Backup
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupPath = "$TargetHtml.bak_$timestamp"
Copy-Item $TargetHtml $backupPath -Force
Write-Host "Backup creato: $backupPath" -ForegroundColor Green

# Widget HTML
$widgetHtml = @'
<!-- GENE1799 TOKEN WIDGET START -->
<div id="gene1799-widget" style="
  margin:18px 0;
  padding:16px;
  border:1px solid #7CFC00;
  border-radius:14px;
  background:rgba(0,0,0,0.65);
  color:#d7ff00;
  font-family:Consolas, monospace;
  box-shadow:0 0 16px rgba(124,252,0,0.15);
">
  <div style="font-size:22px;font-weight:bold;margin-bottom:10px;">
    GENE1799 // TOKEN LIVE
  </div>

  <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(170px,1fr));gap:10px;">
    <div><b>Status</b><br><span id="g1799-status">...</span></div>
    <div><b>Price</b><br><span id="g1799-price">...</span></div>
    <div><b>Liquidity</b><br><span id="g1799-liquidity">...</span></div>
    <div><b>Volume 24h</b><br><span id="g1799-volume">...</span></div>
    <div><b>FDV</b><br><span id="g1799-fdv">...</span></div>
    <div><b>DEX</b><br><span id="g1799-dex">...</span></div>
  </div>

  <div style="margin-top:12px;font-size:12px;color:#9acd32;word-break:break-all;">
    Pair: <span id="g1799-pair">...</span>
  </div>
  <div style="margin-top:6px;font-size:12px;color:#9acd32;word-break:break-all;">
    Update: <span id="g1799-update">...</span>
  </div>
</div>
<!-- GENE1799 TOKEN WIDGET END -->
'@

# Script JS Electron-safe
$widgetScript = @'
<!-- GENE1799 TOKEN SCRIPT START -->
<script>
(function () {
  const fs = require("fs");
  const path = require("path");

  const tokenFile = "C:\\SuiteV17\\TokenModule\\token_data.json";

  function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value;
  }

  function loadGene1799() {
    try {
      const raw = fs.readFileSync(tokenFile, "utf8");
      const data = JSON.parse(raw);

      setText("g1799-status", data.status ?? "-");
      setText("g1799-price", data.price != null ? "$" + data.price : "-");
      setText("g1799-liquidity", data.liquidity != null ? "$" + data.liquidity : "-");
      setText("g1799-volume", data.volume24h != null ? "$" + data.volume24h : "-");
      setText("g1799-fdv", data.fdv != null ? "$" + data.fdv : "-");
      setText("g1799-dex", data.dexId ?? "-");
      setText("g1799-pair", data.pairAddress ?? "-");
      setText("g1799-update", data.lastUpdate ?? "-");
    } catch (err) {
      setText("g1799-status", "errore lettura");
      setText("g1799-price", "-");
      setText("g1799-liquidity", "-");
      setText("g1799-volume", "-");
      setText("g1799-fdv", "-");
      setText("g1799-dex", "-");
      setText("g1799-pair", err.message);
      setText("g1799-update", "-");
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
<!-- GENE1799 TOKEN SCRIPT END -->
'@

$content = Get-Content $TargetHtml -Raw

if ($content -match "GENE1799 TOKEN WIDGET START") {
    Write-Host "Widget già presente. Nessuna doppia iniezione." -ForegroundColor Yellow
}
else {
    if ($content -match "</body>") {
        $replacement = $widgetHtml + "`r`n" + $widgetScript + "`r`n</body>"
        $content = $content -replace "</body>", [Regex]::Escape($replacement)
        $content = $content -replace "\\<", "<"
        $content = $content -replace "\\>", ">"
    }
    else {
        $content += "`r`n" + $widgetHtml + "`r`n" + $widgetScript
    }

    Set-Content -Path $TargetHtml -Value $content -Encoding UTF8
    Write-Host "Widget GENE1799 iniettato nella dashboard Electron." -ForegroundColor Green
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PATCH ELECTRON COMPLETATA " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "File patchato: $TargetHtml" -ForegroundColor White
Write-Host "Backup: $backupPath" -ForegroundColor White
Write-Host ""
Write-Host "Ora riavvia Electron dal progetto." -ForegroundColor Yellow