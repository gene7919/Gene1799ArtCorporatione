# SuiteV17_Complete_Crypto.ps1 - Deploy FULL .env + Agents + BASE Chain
# Salva come C:\SuiteV17\SuiteV17_Complete_Crypto.ps1

param(
    [string]$EnvPath = "C:\SuiteV17\.env"
)

Write-Host "🚀 SUITEV17 CRYPTO COMPLETE - GENE1799 + BASE + Alchemy" -ForegroundColor Green

# 1. CREA .env COMPLETO ✅
$env_content = @"
# SuiteV17 GENE1799 - Multi-Agent Crypto Orchestration
ALCHEMY_BASE_KEY=dd6jel7kzdhxeezy
ALCHEMY_KEY=VPfgdBOReEDP-GkvmgAd
OPENAI_API_KEY=OPENAI_API_KEY_REMOVED
GOOGLE_API_KEY=AIzaSyCIrhoHiSmOGfIKv_pggpm5Rt5rKuVFm5Q
BASE_RPC=https://base-mainnet.g.alchemy.com/v2/dd6jel7kzdhxeezy
ZORA_RPC=https://mainnet.base.org

# GENE1799 Targets
GENE1799_WALLET=0x63800f370b04ce132333c05d811663b80cec788e
GENE1799_TARGET=0x994b342dd87fc825f66e51ffa3ef71ad818b6893
GENE1799_ENSEMBLE=gene1799base.base.eth

# Ollama Models
OLLAMA_MODEL=nemotron-3-super:cloud
OLLAMA_HOST=http://127.0.0.1:11434

# Maestro Services
MACAE_PORT=3000
RAG_PORT=8091
ZORA_AGENT=1
"@

# Salva .env
$env_content | Out-File -FilePath $EnvPath -Encoding UTF8
Write-Host "✅ .env salvato: $EnvPath" -ForegroundColor Yellow

# 2. PM2 AGENTS RESTART
Write-Host "`n🔄 Restarting SuiteV17 Agents..." -ForegroundColor Cyan
pm2 restart all
Start-Sleep 3
pm2 status

# 3. ZORA AGENT FIX (dotenv)
Write-Host "`n🛠️  Fixing zora_nft_agent.py..." -ForegroundColor Magenta
$agent_path = "C:\SuiteV17\zora_nft_agent.py"
if (Test-Path $agent_path) {
    $content = Get-Content $agent_path -Raw
    $fixed = $content -replace "from dotenv import load", "from dotenv import load_dotenv`nload_dotenv()"
    $fixed | Set-Content $agent_path -Encoding UTF8
    Write-Host "✅ zora_nft_agent.py FIXED" -ForegroundColor Green
}

# 4. OLLAMA STATUS
Write-Host "`n🤖 Ollama + RTX 4070 Check..." -ForegroundColor Blue
ollama list | Select-String "nemotron|minimax"

# 5. TEST ENDPOINTS
Write-Host "`n🌐 Testing SuiteV17 Endpoints..." -ForegroundColor Cyan
$endpoints = @(
    "http://localhost:3000/status",
    "http://localhost:8091",
    "http://localhost:11434"
)

foreach ($url in $endpoints) {
    try {
        $resp = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 2 -UseBasicParsing
        Write-Host "✅ $url OK ($($resp.StatusCode))" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️  $url DOWN" -ForegroundColor Red
    }
}

# 6. GENE1799 HEARTBEAT
Write-Host "`n💓 GENE1799 ORCHESTRA LIVE:" -ForegroundColor Green
Write-Host "  🖼️  Macae (minimax): http://localhost:3000/status"
Write-Host "  🌉 RAG Bridge:      http://localhost:8091"
Write-Host "  🔍 Zora Agent:      pm2 logs zora_agent -f" 
Write-Host "  🧠 Ollama NEMOTRON: http://localhost:11434"
Write-Host "  🎯 Target Wallet:   0x994b342dd87fc825f66e51ffa3ef71ad818b6893"

# 7. LAUNCH DASHBOARD
Write-Host "`n🎬 Opening Dashboard..." -ForegroundColor Yellow
Start-Process "http://localhost:3000/status"

Write-Host "`n🎉 SUITEV17 COMPLETE DEPLOYED! GENE1799 + BASE + Zora LIVE" -ForegroundColor Green
Write-Host "💡 Prossimo: pm2 logs zora_agent -f" -ForegroundColor Yellow


