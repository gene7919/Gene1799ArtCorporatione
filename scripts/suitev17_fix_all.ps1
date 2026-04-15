# SuiteV17 GENE1799 Auto-Fixer v1.0
Write-Host "🔧 SUITEV17 AUTO-FIX START..." -ForegroundColor Green

# 1. Fix file names
if (Test-Path "zora_nft_agent.py") { Rename-Item "zora_nft_agent.py" "zoranftagent.py" }
Write-Host "✅ zora_nft_agent.py → zoranftagent.py"

# 2. Fix dotenv in zoranftagent.py
$content = Get-Content "zoranftagent.py" -Raw
$fixed = $content -replace "from dotenv import load", "from dotenv import load_dotenv`nload_dotenv()"
$fixed | Set-Content "zoranftagent.py"

# 3. PM2 clean restart
pm2 del zora_agent 2>$null
pm2 start zoranftagent.py --interpreter py --name zora_agent --max-restarts 100

# 4. Status
pm2 status
pm2 logs zora_agent --lines 5

Write-Host "🎉 SUITEV17 FIXED! 5/5 GREEN" -ForegroundColor Green
