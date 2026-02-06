# ════════════════════════════════════════════════════════════════════
# GENE1799 - AUTOMAZIONE DEPLOY A RENDER + DNS PORKBUN
# ════════════════════════════════════════════════════════════════════

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   🚀 GENE1799 DEPLOYMENT AUTOMATION - RENDER + PORKBUN    ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Configuration
$GitRepo = "c:\Users\gene1\Desktop\gene1799\Gene1799ArtCorporatione"
$RendererDashboard = "https://dashboard.render.com/static/new"
$PorkbunDomainManager = "https://porkbun.com/account/domainsSpeedy"
$Domain = "gene1799artcorporatione.mom"
$RenderService = "gene1799-art.onrender.com"

# Step 1: Final Git Push
Write-Host "📦 STEP 1: Finalizing GitHub push..." -ForegroundColor Yellow
Write-Host ""

Set-Location $GitRepo

Write-Host "  ✓ Adding all files..." -ForegroundColor Green
git add -A

Write-Host "  ✓ Creating commit..." -ForegroundColor Green
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
git commit -m "Final deployment: Gene1799 ready for production - $timestamp"

Write-Host "  ✓ Pushing to GitHub..." -ForegroundColor Green
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  ✅ GitHub push completed successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  ⚠️  GitHub push status - check output above" -ForegroundColor Yellow
}

Write-Host ""

# Step 2: Summary & Instructions
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║   ✅ DEPLOYMENT PREPARATION COMPLETE                      ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "📋 NEXT STEPS TO GO LIVE:" -ForegroundColor Cyan
Write-Host ""

Write-Host "┌─ PASSO 1: Create Render Service" -ForegroundColor White
Write-Host "│" -ForegroundColor White
Write-Host "│  1. Open: $RendererDashboard" -ForegroundColor Gray
Write-Host "│  2. Click 'New +' → 'Static Site'" -ForegroundColor Gray
Write-Host "│  3. Connect GitHub & select: gene7919/Gene1799ArtCorporatione" -ForegroundColor Gray
Write-Host "│  4. Configure:" -ForegroundColor Gray
Write-Host "│     • Branch: main" -ForegroundColor Gray
Write-Host "│     • Root Directory: . (dot)" -ForegroundColor Gray
Write-Host "│     • Publish Directory: . (dot)" -ForegroundColor Gray
Write-Host "│     • Name: gene1799-art" -ForegroundColor Gray
Write-Host "│  5. Click 'Create Static Site'" -ForegroundColor Gray
Write-Host "│" -ForegroundColor White
Write-Host "└─ Tempo: ~5 minuti" -ForegroundColor White
Write-Host ""

Write-Host "┌─ PASSO 2: Configure DNS on Porkbun" -ForegroundColor White
Write-Host "│" -ForegroundColor White
Write-Host "│  1. Open: $PorkbunDomainManager" -ForegroundColor Gray
Write-Host "│  2. Select domain: $Domain" -ForegroundColor Gray
Write-Host "│  3. Add/Edit these DNS Records:" -ForegroundColor Gray
Write-Host "│" -ForegroundColor Gray
Write-Host "│     TYPE: CNAME" -ForegroundColor Magenta
Write-Host "│     HOST: @" -ForegroundColor Magenta
Write-Host "│     VALUE: $RenderService" -ForegroundColor Magenta
Write-Host "│     TTL: 300" -ForegroundColor Magenta
Write-Host "│" -ForegroundColor Gray
Write-Host "│     (REPEAT FOR www HOST)" -ForegroundColor Magenta
Write-Host "│" -ForegroundColor Gray
Write-Host "│  4. Save changes" -ForegroundColor Gray
Write-Host "│  5. Wait 5-30 minutes for DNS propagation" -ForegroundColor Gray
Write-Host "│" -ForegroundColor White
Write-Host "└─ Tempo: ~2 minuti + 5-30 min DNS propagation" -ForegroundColor White
Write-Host ""

Write-Host "┌─ PASSO 3: Verify Live!" -ForegroundColor White
Write-Host "│" -ForegroundColor White
Write-Host "│  Test commands (after DNS propagation):" -ForegroundColor Gray
Write-Host "│" -ForegroundColor Gray
Write-Host "│  dig $Domain +short" -ForegroundColor Magenta
Write-Host "│  ping $Domain" -ForegroundColor Magenta
Write-Host "│" -ForegroundColor Gray
Write-Host "│  Then visit: https://$Domain" -ForegroundColor Green
Write-Host "│" -ForegroundColor White
Write-Host "└─ Tempo: Instant" -ForegroundColor White
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 3: Open dashboards
Write-Host "🌐 Opening dashboards..." -ForegroundColor Yellow
Write-Host ""

Write-Host "  → Opening Render Dashboard..." -ForegroundColor Gray
Start-Process $RendererDashboard

Start-Sleep -Seconds 2

Write-Host "  → Opening Porkbun Domain Manager..." -ForegroundColor Gray
Start-Process $PorkbunDomainManager

Write-Host ""
Write-Host "✅ Dashboards opened! Follow the steps above." -ForegroundColor Green
Write-Host ""

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "🎉 GENE1799 IS GOING LIVE! 🎉" -ForegroundColor Magenta
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
