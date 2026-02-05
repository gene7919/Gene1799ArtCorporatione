# Gene1799 Quick Deploy v9.1
# Usage: .\DEPLOY.ps1 "commit message"

param(
    [string]$Message = "Update backend"
)

Write-Host @"

╔════════════════════════════════════════════════════════════════════╗
║              GENE1799 QUICK DEPLOY TO PRODUCTION                  ║
╚════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

Write-Host "📦 Preparing deployment..." -ForegroundColor Yellow
Write-Host ""

# Verify files
if (-not (Test-Path "backend/server.js")) {
    Write-Host "❌ server.js not found!" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path "backend/package.json")) {
    Write-Host "❌ package.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Files verified" -ForegroundColor Green

# Git operations
Write-Host "📤 Committing changes..." -ForegroundColor Yellow

git add backend/
git commit -m "$Message"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ℹ️  No changes to commit" -ForegroundColor Cyan
}

Write-Host "🚀 Pushing to GitHub..." -ForegroundColor Yellow
git push origin master

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Pushed successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "⏳ Render will auto-deploy in 1-2 minutes" -ForegroundColor Cyan
    Write-Host "🔍 Monitor: https://dashboard.render.com/web/srv-d620hokhg0os73845100/logs" -ForegroundColor White
} else {
    Write-Host "❌ Push failed!" -ForegroundColor Red
    exit 1
}

Write-Host ""
