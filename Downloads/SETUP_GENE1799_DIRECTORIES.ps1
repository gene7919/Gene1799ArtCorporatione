# ═══════════════════════════════════════════════════════════
# 🚀 GENE1799 DIRECTORY SETUP AUTOMATICO
# Crea tutta la struttura di directory necessaria
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "║     🚀 GENE1799 AUTOMATIC DIRECTORY SETUP 🚀            ║" -ForegroundColor Cyan
Write-Host "║                                                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

Write-Host "Creazione struttura completa di directory...`n" -ForegroundColor Yellow

# Conta le directory create
$createdCount = 0
$existingCount = 0

# Funzione helper per creare directory
function New-DirectoryIfNotExists {
    param([string]$Path, [string]$Description = "")
    
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Host "✓ Creata: " -ForegroundColor Green -NoNewline
        Write-Host $Path -ForegroundColor White
        if ($Description) {
            Write-Host "  → $Description" -ForegroundColor Gray
        }
        $script:createdCount++
    } else {
        Write-Host "○ Esiste: " -ForegroundColor Yellow -NoNewline
        Write-Host $Path -ForegroundColor White
        $script:existingCount++
    }
}

# ═══════════════════════════════════════════════════════════
# DISCO C: - AI CORE
# ═══════════════════════════════════════════════════════════

Write-Host "`n📁 DISCO C: - AI CORE" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

New-DirectoryIfNotExists "C:\AI" "Core AI principale"
New-DirectoryIfNotExists "C:\AI\Models" "Modelli AI locali"
New-DirectoryIfNotExists "C:\AI\Agents" "Agenti (copia locale)"
New-DirectoryIfNotExists "C:\AI\Cache" "Cache inferenza"

# ═══════════════════════════════════════════════════════════
# DISCO D: - GENE1799 CORE
# ═══════════════════════════════════════════════════════════

Write-Host "`n📁 DISCO D: - GENE1799 CORE" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

New-DirectoryIfNotExists "D:\Gene1799" "Hub centrale GENE1799"
New-DirectoryIfNotExists "D:\Gene1799\Modules" "Moduli sistema"
New-DirectoryIfNotExists "D:\Gene1799\Agents" "Agenti (configurazioni)"
New-DirectoryIfNotExists "D:\Gene1799\Synaptic" "Rete sinaptica"
New-DirectoryIfNotExists "D:\Gene1799\Synaptic\Weights" "Pesi neurali"
New-DirectoryIfNotExists "D:\Gene1799\Logs" "Log sistema"
New-DirectoryIfNotExists "D:\Gene1799\Logs\Agents" "Log agenti"
New-DirectoryIfNotExists "D:\Gene1799\Database" "Database sistema"
New-DirectoryIfNotExists "D:\Gene1799\Explorer" "Script principali"

# ═══════════════════════════════════════════════════════════
# DISCO D: - ELECTRONIC
# ═══════════════════════════════════════════════════════════

Write-Host "`n📁 DISCO D: - ELECTRONIC SYSTEMS" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

New-DirectoryIfNotExists "D:\Electronic" "Sistemi elettronici"
New-DirectoryIfNotExists "D:\Electronic\Modules" "Moduli elettronici"
New-DirectoryIfNotExists "D:\Electronic\Data" "Dati elettronici"
New-DirectoryIfNotExists "D:\Electronic\Agents" "Agenti elettronici"

# ═══════════════════════════════════════════════════════════
# DISCO E: - AI EXTENDED (controlla se esiste)
# ═══════════════════════════════════════════════════════════

Write-Host "`n📁 DISCO E: - AI EXTENDED STORAGE" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray

# Verifica se disco E: esiste
if (Test-Path "E:\") {
    Write-Host "Disco E: trovato! Creazione struttura AI Extended..." -ForegroundColor Green
    
    New-DirectoryIfNotExists "E:\GENE1799_AI" "AI Extended principale"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Models" "Storage modelli esteso"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Training" "Dati training"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Results" "Risultati AI"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Backups" "Backup sistema"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers" "Provider-specific"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers\OpenAI" "OpenAI storage"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers\Anthropic" "Anthropic storage"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers\Google" "Google storage"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers\HuggingFace" "HuggingFace storage"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers\Ollama" "Ollama storage"
    New-DirectoryIfNotExists "E:\GENE1799_AI\Providers\StabilityAI" "StabilityAI storage"
} else {
    Write-Host "⚠️  Disco E: non trovato!" -ForegroundColor Red
    Write-Host "   Creo struttura alternativa su D:\Gene1799\AI_Extended..." -ForegroundColor Yellow
    
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended" "AI Extended su D:"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Models" "Storage modelli esteso"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Training" "Dati training"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Results" "Risultati AI"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Backups" "Backup sistema"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers" "Provider-specific"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers\OpenAI" "OpenAI storage"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers\Anthropic" "Anthropic storage"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers\Google" "Google storage"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers\HuggingFace" "HuggingFace storage"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers\Ollama" "Ollama storage"
    New-DirectoryIfNotExists "D:\Gene1799\AI_Extended\Providers\StabilityAI" "StabilityAI storage"
}

# ═══════════════════════════════════════════════════════════
# SOMMARIO FINALE
# ═══════════════════════════════════════════════════════════

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                    ✅ SETUP COMPLETATO ✅                 ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green

Write-Host "📊 Statistiche:" -ForegroundColor Cyan
Write-Host "   Directory create: " -NoNewline -ForegroundColor White
Write-Host $createdCount -ForegroundColor Green
Write-Host "   Directory esistenti: " -NoNewline -ForegroundColor White
Write-Host $existingCount -ForegroundColor Yellow
Write-Host "   Totale: " -NoNewline -ForegroundColor White
Write-Host ($createdCount + $existingCount) -ForegroundColor Cyan

# Mostra struttura dischi
Write-Host "`n💾 Struttura Dischi:" -ForegroundColor Cyan
Write-Host "   C:\AI                 - AI Core" -ForegroundColor White
Write-Host "   D:\Gene1799           - GENE1799 Core" -ForegroundColor White
Write-Host "   D:\Electronic         - Electronic Systems" -ForegroundColor White

if (Test-Path "E:\") {
    Write-Host "   E:\GENE1799_AI        - AI Extended Storage" -ForegroundColor White
} else {
    Write-Host "   D:\Gene1799\AI_Extended - AI Extended (alternativo)" -ForegroundColor Yellow
}

Write-Host "`n🎯 Prossimi Passi:" -ForegroundColor Yellow
Write-Host "   1. Copia gli script PS1 in: D:\Gene1799\Explorer\" -ForegroundColor Gray
Write-Host "   2. Esegui: .\gene1799_ai_integration_core.ps1 -Mode INIT" -ForegroundColor Gray
Write-Host "   3. Configura API keys (opzionale)" -ForegroundColor Gray
Write-Host "   4. Crea i tuoi primi agenti!" -ForegroundColor Gray

Write-Host "`n✨ Sistema pronto per l'uso! ✨`n" -ForegroundColor Green
