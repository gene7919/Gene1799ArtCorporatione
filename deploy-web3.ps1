# ───────────── DEPLOY WEB3 AUTOMATICO ─────────────
param(
    [string]$LocalPath   = "C:\Users\gene1\Gene1799ArtCorporatione\Web",
    [string]$RepoURL     = "https://github.com/gene7919/Gene1799ArtCorporatione.git",
    [string]$UserName    = "Gene1799ArtCorporatione",
    [string]$UserEmail   = "gene1799artcorporatione@gmail.com",
    [string]$GitHubToken = "10083709"
)

# ───────────── CREA STRUTTURA CARTELLA ─────────────
if (-not (Test-Path $LocalPath)) { New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null }
$JSPath = Join-Path $LocalPath "js"
if (-not (Test-Path $JSPath)) { New-Item -ItemType Directory -Path $JSPath -Force | Out-Null }

# ───────────── CREA index.html ─────────────
$indexHtml = @"
<!DOCTYPE html>
<html lang="it">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>GENE1799 Art Corporatione</title>
<link rel="stylesheet" href="style.css">
<script src="https://cdn.ethers.io/lib/ethers-5.7.umd.min.js" type="application/javascript"></script>
<script src="./js/web3-integration.js" type="module"></script>
</head>
<body>
<h1>GENE1799 Art Corporatione - Web3</h1>

<div id="web3-status" class="web3-status"></div>
<button id="connect-wallet-btn">🦊 CONNECT METAMASK</button>

<div id="wallet-info" style="display:none;">
  <p>Wallet: <span id="wallet-address"></span></p>
  <p>Balance: <span id="token-balance">0 $GENE1799</span></p>
</div>

<div id="nft-check-result" style="display:none;">
  <div id="nft-result-content"></div>
</div>

</body>
</html>
"@
Set-Content -Path (Join-Path $LocalPath "index.html") -Value $indexHtml -Force

# ───────────── CREA style.css ─────────────
$styleCss = @"
body { font-family: Arial, sans-serif; margin: 20px; background-color: #111; color: #fff; }
button { padding: 10px 20px; margin: 10px 0; cursor: pointer; }
.web3-status { margin: 10px 0; padding: 10px; border-radius: 5px; }
.text-green { color: #0f0; }
.text-gold { color: #ffd700; }
.text-cyan { color: #0ff; }
.text-secondary { color: #888; }
"@
Set-Content -Path (Join-Path $LocalPath "style.css") -Value $styleCss -Force

# ───────────── CREA web3-integration.js ─────────────
$web3Js = @"
// Template Web3 Gene1799 - placeholder
console.log('Web3Integration loaded!');
// Qui puoi incollare tutto il tuo Web3Integration JS Gene1799
"@
Set-Content -Path (Join-Path $JSPath "web3-integration.js") -Value $web3Js -Force

# ───────────── INIZIALIZZA GIT ─────────────
Set-Location $LocalPath
if (-not (Test-Path ".git")) { git init }
git config user.name  $UserName
git config user.email $UserEmail

# ───────────── AGGIUNGE REMOTE ─────────────
$remotes = git remote
if ($remotes -notcontains "origin") { git remote add origin $RepoURL }

# ───────────── COMMIT E PUSH ─────────────
git add .
$commitMessage = "Deploy Web3 automatico $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m "$commitMessage" -ErrorAction SilentlyContinue

$pushURL = $RepoURL -replace "https://", "https://$GitHubToken@"

try {
    git push $pushURL main
} catch {
    Write-Host "⚠️ Push fallito, provo con --force..."
    git push $pushURL main --force
}

Write-Host "✅ Deploy Web3 completato. Controlla il tuo repository GitHub!" -ForegroundColor Green
