#Requires -Version 7.0
<#
.SYNOPSIS
    GENE1799 Intelligent File Manager - Gestione File AI
.DESCRIPTION
    Sistema di gestione file intelligente con auto-organizzazione,
    rilevamento duplicati, tagging automatico e apprendimento pattern
.AUTHOR
    Gene1799 Art Corporation
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('ORGANIZE','ANALYZE','CLEANUP','BACKUP','AUTO','STATUS')]
    [string]$Mode = 'AUTO',
    
    [Parameter(Mandatory=$false)]
    [string]$TargetPath = "$env:USERPROFILE\Downloads",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Importa il Core
. "D:\Gene1799\Explorer\gene1799_ai_integration_core.ps1" -Mode START

# ═══════════════════════════════════════════════════════════════════
#  CONFIGURAZIONE FILE MANAGER
# ═══════════════════════════════════════════════════════════════════

$Global:FileManagerConfig = @{
    RulesPath = "D:\Gene1799\Explorer\Data\FileRules"
    PatternsPath = "D:\Gene1799\Explorer\Data\FilePatterns"
    BackupPath = "D:\Gene1799\Explorer\Backup"
    
    # Categorie automatiche
    Categories = @{
        Documents = @{
            Extensions = @('.pdf', '.doc', '.docx', '.txt', '.rtf', '.odt', '.xlsx', '.xls', '.pptx', '.ppt')
            BasePath = "$env:USERPROFILE\Documents\Organized"
            SubFolders = @{
                Work = @('report', 'meeting', 'project', 'contract', 'invoice')
                Personal = @('personal', 'family', 'health', 'finance')
                Education = @('course', 'tutorial', 'learning', 'study')
            }
        }
        Images = @{
            Extensions = @('.jpg', '.jpeg', '.png', '.gif', '.bmp', '.svg', '.webp', '.ico')
            BasePath = "$env:USERPROFILE\Pictures\Organized"
            SubFolders = @{
                Screenshots = @('screenshot', 'capture', 'screen')
                Photos = @('photo', 'img', 'picture', 'camera')
                Graphics = @('design', 'logo', 'icon', 'graphic')
                Wallpapers = @('wallpaper', 'background', 'wall')
            }
        }
        Videos = @{
            Extensions = @('.mp4', '.avi', '.mkv', '.mov', '.wmv', '.flv', '.webm')
            BasePath = "$env:USERPROFILE\Videos\Organized"
            SubFolders = @{
                Recordings = @('record', 'recording', 'capture')
                Movies = @('movie', 'film')
                Tutorials = @('tutorial', 'course', 'lesson')
            }
        }
        Audio = @{
            Extensions = @('.mp3', '.wav', '.flac', '.aac', '.ogg', '.wma', '.m4a')
            BasePath = "$env:USERPROFILE\Music\Organized"
            SubFolders = @{
                Music = @('music', 'song', 'track')
                Podcasts = @('podcast', 'episode')
                Recordings = @('record', 'voice', 'audio')
            }
        }
        Archives = @{
            Extensions = @('.zip', '.rar', '.7z', '.tar', '.gz', '.bz2')
            BasePath = "$env:USERPROFILE\Downloads\Archives"
            SubFolders = @{}
        }
        Programs = @{
            Extensions = @('.exe', '.msi', '.dmg', '.pkg', '.deb', '.rpm')
            BasePath = "$env:USERPROFILE\Downloads\Programs"
            SubFolders = @{}
        }
        Code = @{
            Extensions = @('.py', '.js', '.html', '.css', '.java', '.cpp', '.cs', '.ps1', '.sh', '.rb')
            BasePath = "$env:USERPROFILE\Documents\Code"
            SubFolders = @{
                Scripts = @('script', 'automation')
                Projects = @('project', 'app', 'web')
            }
        }
    }
    
    # Regole di pulizia
    CleanupRules = @{
        TempFiles = @('.tmp', '.temp', '.cache', '.log')
        OldFiles = 90  # giorni
        DuplicateStrategy = 'KeepNewest'
    }
    
    # Intelligenza
    LearningEnabled = $true
    AutoTagging = $true
    SmartNaming = $true
}

# ═══════════════════════════════════════════════════════════════════
#  FUNZIONI DI ANALISI
# ═══════════════════════════════════════════════════════════════════

function Get-FileIntelligence {
    param([System.IO.FileInfo]$File)
    
    $intelligence = @{
        File = $File
        Category = $null
        SubCategory = $null
        Tags = @()
        ImportanceScore = 0
        SuggestedPath = $null
        Confidence = 0.0
    }
    
    # Determina categoria
    foreach ($category in $Global:FileManagerConfig.Categories.Keys) {
        $config = $Global:FileManagerConfig.Categories[$category]
        if ($config.Extensions -contains $File.Extension.ToLower()) {
            $intelligence.Category = $category
            $intelligence.Confidence += 0.3
            break
        }
    }
    
    if (-not $intelligence.Category) {
        $intelligence.Category = "Other"
        $intelligence.SuggestedPath = "$env:USERPROFILE\Documents\Other"
        return $intelligence
    }
    
    # Analizza nome file per sub-categoria
    $fileName = $File.BaseName.ToLower()
    $categoryConfig = $Global:FileManagerConfig.Categories[$intelligence.Category]
    
    foreach ($subCat in $categoryConfig.SubFolders.Keys) {
        $keywords = $categoryConfig.SubFolders[$subCat]
        foreach ($keyword in $keywords) {
            if ($fileName -like "*$keyword*") {
                $intelligence.SubCategory = $subCat
                $intelligence.Confidence += 0.3
                break
            }
        }
        if ($intelligence.SubCategory) { break }
    }
    
    # Genera tags automatici
    $intelligence.Tags += Get-AutoTags -FileName $fileName
    if ($intelligence.Tags.Count -gt 0) {
        $intelligence.Confidence += 0.2
    }
    
    # Calcola importanza
    $intelligence.ImportanceScore = Get-FileImportance -File $File -Intelligence $intelligence
    
    # Suggerisci path
    if ($intelligence.SubCategory) {
        $intelligence.SuggestedPath = Join-Path $categoryConfig.BasePath $intelligence.SubCategory
    }
    else {
        $intelligence.SuggestedPath = $categoryConfig.BasePath
    }
    
    return $intelligence
}

function Get-AutoTags {
    param([string]$FileName)
    
    $tags = @()
    
    # Date patterns
    if ($FileName -match '\d{4}[-_]\d{2}[-_]\d{2}') {
        $tags += "dated"
    }
    
    # Common keywords
    $keywords = @{
        'important' = @('important', 'urgent', 'critical', 'final')
        'draft' = @('draft', 'wip', 'temp', 'test')
        'work' = @('work', 'job', 'office', 'business')
        'personal' = @('personal', 'private', 'home')
        'backup' = @('backup', 'copy', 'archive')
    }
    
    foreach ($tag in $keywords.Keys) {
        foreach ($keyword in $keywords[$tag]) {
            if ($FileName -like "*$keyword*") {
                $tags += $tag
                break
            }
        }
    }
    
    return $tags
}

function Get-FileImportance {
    param(
        [System.IO.FileInfo]$File,
        [hashtable]$Intelligence
    )
    
    $score = 50  # Base score
    
    # File size (larger = more important)
    if ($File.Length -gt 10MB) { $score += 20 }
    elseif ($File.Length -gt 1MB) { $score += 10 }
    
    # Recently modified
    $daysSinceModified = (Get-Date) - $File.LastWriteTime
    if ($daysSinceModified.Days -lt 7) { $score += 20 }
    elseif ($daysSinceModified.Days -lt 30) { $score += 10 }
    
    # Important tags
    if ($Intelligence.Tags -contains 'important') { $score += 30 }
    if ($Intelligence.Tags -contains 'work') { $score += 15 }
    
    # High confidence = important
    $score += [int]($Intelligence.Confidence * 20)
    
    return [math]::Min($score, 100)
}

function Find-DuplicateFiles {
    param([string]$Path)
    
    $Global:Gene1799Core.WriteLog.Invoke("🔍 Ricerca duplicati in: $Path", "INFO")
    
    $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
    $hashes = @{}
    $duplicates = @()
    
    foreach ($file in $files) {
        try {
            $hash = Get-FileHash -Path $file.FullName -Algorithm MD5
            
            if ($hashes.ContainsKey($hash.Hash)) {
                $duplicates += @{
                    Original = $hashes[$hash.Hash]
                    Duplicate = $file
                    Size = $file.Length
                }
                $Global:Gene1799Core.WriteLog.Invoke("  ⚠ Duplicato: $($file.Name)", "WARNING")
            }
            else {
                $hashes[$hash.Hash] = $file
            }
        }
        catch {
            # Skip files that can't be accessed
        }
    }
    
    return $duplicates
}

# ═══════════════════════════════════════════════════════════════════
#  FUNZIONI DI ORGANIZZAZIONE
# ═══════════════════════════════════════════════════════════════════

function Start-IntelligentOrganization {
    param(
        [string]$SourcePath,
        [switch]$DryRun
    )
    
    $Global:Gene1799Core.WriteLog.Invoke("🗂️ Inizio organizzazione intelligente: $SourcePath", "INFO")
    
    if (-not (Test-Path $SourcePath)) {
        $Global:Gene1799Core.WriteLog.Invoke("❌ Path non trovato: $SourcePath", "ERROR")
        return
    }
    
    $files = Get-ChildItem -Path $SourcePath -File -ErrorAction SilentlyContinue
    $stats = @{
        Total = $files.Count
        Organized = 0
        Skipped = 0
        Errors = 0
    }
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║           ORGANIZZAZIONE INTELLIGENTE FILES              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "`nFile da processare: $($files.Count)" -ForegroundColor Yellow
    
    if ($DryRun) {
        Write-Host "⚠️  MODALITÀ DRY-RUN - Nessun file sarà spostato" -ForegroundColor Yellow
    }
    
    foreach ($file in $files) {
        Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
        Write-Host "📄 $($file.Name)" -ForegroundColor White
        
        # Analizza file
        $intelligence = Get-FileIntelligence -File $file
        
        Write-Host "  Categoria: $($intelligence.Category)" -ForegroundColor Cyan
        if ($intelligence.SubCategory) {
            Write-Host "  Sub-categoria: $($intelligence.SubCategory)" -ForegroundColor Cyan
        }
        Write-Host "  Importanza: $($intelligence.ImportanceScore)/100" -ForegroundColor $(if ($intelligence.ImportanceScore -gt 70) {"Green"} elseif ($intelligence.ImportanceScore -gt 40) {"Yellow"} else {"Gray"})
        Write-Host "  Confidenza: $($intelligence.Confidence.ToString('P0'))" -ForegroundColor Magenta
        
        if ($intelligence.Tags.Count -gt 0) {
            Write-Host "  Tags: $($intelligence.Tags -join ', ')" -ForegroundColor Gray
        }
        
        Write-Host "  → $($intelligence.SuggestedPath)" -ForegroundColor Green
        
        # Sposta file
        if (-not $DryRun) {
            try {
                # Crea directory se non esiste
                if (-not (Test-Path $intelligence.SuggestedPath)) {
                    New-Item -Path $intelligence.SuggestedPath -ItemType Directory -Force | Out-Null
                }
                
                $destPath = Join-Path $intelligence.SuggestedPath $file.Name
                
                # Gestisci conflitti nome
                if (Test-Path $destPath) {
                    $baseName = $file.BaseName
                    $extension = $file.Extension
                    $counter = 1
                    
                    do {
                        $newName = "${baseName}_$counter$extension"
                        $destPath = Join-Path $intelligence.SuggestedPath $newName
                        $counter++
                    } while (Test-Path $destPath)
                }
                
                Move-Item -Path $file.FullName -Destination $destPath -Force
                Write-Host "  ✅ Spostato con successo!" -ForegroundColor Green
                
                $stats.Organized++
                
                # Registra esperienza
                $Global:Gene1799Core.AddExperience.Invoke(
                    "FileManager",
                    "OrganizeFile",
                    $intelligence.Category,
                    $true,
                    "Moved to $($intelligence.SuggestedPath)",
                    @{
                        FileName = $file.Name
                        Category = $intelligence.Category
                        Confidence = $intelligence.Confidence
                    }
                )
            }
            catch {
                Write-Host "  ❌ Errore: $($_.Exception.Message)" -ForegroundColor Red
                $stats.Errors++
                
                $Global:Gene1799Core.AddExperience.Invoke(
                    "FileManager",
                    "OrganizeFile",
                    $intelligence.Category,
                    $false,
                    $_.Exception.Message,
                    @{FileName = $file.Name}
                )
            }
        }
        else {
            $stats.Organized++
        }
        
        Start-Sleep -Milliseconds 200
    }
    
    # Report finale
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              ORGANIZZAZIONE COMPLETATA                    ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n📊 Statistiche:" -ForegroundColor Magenta
    Write-Host "  File totali: $($stats.Total)" -ForegroundColor Cyan
    Write-Host "  Organizzati: $($stats.Organized)" -ForegroundColor Green
    Write-Host "  Errori: $($stats.Errors)" -ForegroundColor Red
    
    $Global:Gene1799Core.WriteLog.Invoke(
        "✅ Organizzazione completata: $($stats.Organized)/$($stats.Total) file", 
        "SUCCESS"
    )
}

function Start-CleanupOperation {
    param([string]$Path)
    
    $Global:Gene1799Core.WriteLog.Invoke("🧹 Inizio pulizia: $Path", "INFO")
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║                 PULIZIA AUTOMATICA                        ║" -ForegroundColor Yellow
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
    
    $cleaned = @{
        TempFiles = 0
        OldFiles = 0
        Duplicates = 0
        SpaceFreed = 0
    }
    
    # 1. Rimuovi file temporanei
    Write-Host "`n🗑️ Rimozione file temporanei..." -ForegroundColor Cyan
    $tempExtensions = $Global:FileManagerConfig.CleanupRules.TempFiles
    
    foreach ($ext in $tempExtensions) {
        $tempFiles = Get-ChildItem -Path $Path -Filter "*$ext" -File -Recurse -ErrorAction SilentlyContinue
        
        foreach ($file in $tempFiles) {
            try {
                $size = $file.Length
                Remove-Item -Path $file.FullName -Force
                $cleaned.TempFiles++
                $cleaned.SpaceFreed += $size
                Write-Host "  ✓ Rimosso: $($file.Name)" -ForegroundColor Gray
            }
            catch {
                Write-Host "  ✗ Errore: $($file.Name)" -ForegroundColor Red
            }
        }
    }
    
    # 2. File vecchi
    Write-Host "`n📅 Ricerca file vecchi (>$($Global:FileManagerConfig.CleanupRules.OldFiles) giorni)..." -ForegroundColor Cyan
    $cutoffDate = (Get-Date).AddDays(-$Global:FileManagerConfig.CleanupRules.OldFiles)
    $oldFiles = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
        Where-Object {$_.LastWriteTime -lt $cutoffDate -and $_.Extension -in $tempExtensions}
    
    foreach ($file in $oldFiles) {
        Write-Host "  ⚠ File vecchio: $($file.Name) - $($file.LastWriteTime.ToString('yyyy-MM-dd'))" -ForegroundColor Yellow
    }
    
    # 3. Duplicati
    Write-Host "`n🔍 Ricerca duplicati..." -ForegroundColor Cyan
    $duplicates = Find-DuplicateFiles -Path $Path
    
    if ($duplicates.Count -gt 0) {
        Write-Host "  Trovati $($duplicates.Count) file duplicati" -ForegroundColor Yellow
        
        foreach ($dup in $duplicates) {
            $spaceWaste = $dup.Size / 1MB
            Write-Host "  📋 $($dup.Duplicate.Name) - $($spaceWaste.ToString('F2')) MB" -ForegroundColor Gray
            Write-Host "     Originale: $($dup.Original.FullName)" -ForegroundColor DarkGray
        }
    }
    
    # Report finale
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                PULIZIA COMPLETATA                         ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host "`n📊 Risultati:" -ForegroundColor Magenta
    Write-Host "  File temp rimossi: $($cleaned.TempFiles)" -ForegroundColor Cyan
    Write-Host "  File vecchi trovati: $($oldFiles.Count)" -ForegroundColor Cyan
    Write-Host "  Duplicati trovati: $($duplicates.Count)" -ForegroundColor Cyan
    Write-Host "  Spazio liberato: $($($cleaned.SpaceFreed / 1MB).ToString('F2')) MB" -ForegroundColor Green
    
    $Global:Gene1799Core.WriteLog.Invoke(
        "✅ Pulizia completata: $($cleaned.TempFiles) file rimossi, $($($cleaned.SpaceFreed / 1MB).ToString('F2')) MB liberati", 
        "SUCCESS"
    )
}

function Start-BackupOperation {
    param([string]$SourcePath)
    
    $Global:Gene1799Core.WriteLog.Invoke("💾 Inizio backup: $SourcePath", "INFO")
    
    $backupName = "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    $backupPath = Join-Path $Global:FileManagerConfig.BackupPath $backupName
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                   BACKUP IN CORSO                         ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    try {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
        
        $files = Get-ChildItem -Path $SourcePath -Recurse -ErrorAction SilentlyContinue
        $total = $files.Count
        $current = 0
        
        foreach ($file in $files) {
            $current++
            $percent = [int](($current / $total) * 100)
            
            Write-Progress -Activity "Backup in corso" -Status "$percent% ($current/$total)" -PercentComplete $percent
            
            $relativePath = $file.FullName.Substring($SourcePath.Length + 1)
            $destPath = Join-Path $backupPath $relativePath
            $destDir = Split-Path -Parent $destPath
            
            if (-not (Test-Path $destDir)) {
                New-Item -Path $destDir -ItemType Directory -Force | Out-Null
            }
            
            if ($file.PSIsContainer -eq $false) {
                Copy-Item -Path $file.FullName -Destination $destPath -Force
            }
        }
        
        Write-Progress -Activity "Backup" -Completed
        
        Write-Host "`n✅ Backup completato!" -ForegroundColor Green
        Write-Host "📁 Path: $backupPath" -ForegroundColor Cyan
        Write-Host "📊 File copiati: $total" -ForegroundColor Cyan
        
        $Global:Gene1799Core.WriteLog.Invoke("✅ Backup completato: $total file → $backupPath", "SUCCESS")
    }
    catch {
        Write-Host "`n❌ Errore durante il backup: $($_.Exception.Message)" -ForegroundColor Red
        $Global:Gene1799Core.WriteLog.Invoke("❌ Errore backup: $($_.Exception.Message)", "ERROR")
    }
}

function Get-FileStatistics {
    param([string]$Path)
    
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              ANALISI DIRECTORY                            ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    $files = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
    
    # Statistiche generali
    $totalSize = ($files | Measure-Object -Property Length -Sum).Sum
    $categoryStats = @{}
    
    foreach ($file in $files) {
        $intel = Get-FileIntelligence -File $file
        
        if (-not $categoryStats.ContainsKey($intel.Category)) {
            $categoryStats[$intel.Category] = @{
                Count = 0
                Size = 0
            }
        }
        
        $categoryStats[$intel.Category].Count++
        $categoryStats[$intel.Category].Size += $file.Length
    }
    
    Write-Host "`n📊 Statistiche Generali:" -ForegroundColor Magenta
    Write-Host "  File totali: $($files.Count)" -ForegroundColor Cyan
    Write-Host "  Dimensione totale: $($($totalSize / 1GB).ToString('F2')) GB" -ForegroundColor Cyan
    
    Write-Host "`n📁 Per Categoria:" -ForegroundColor Magenta
    foreach ($cat in $categoryStats.Keys | Sort-Object) {
        $stats = $categoryStats[$cat]
        $sizeGB = $stats.Size / 1GB
        Write-Host "  $cat" -ForegroundColor Yellow
        Write-Host "    File: $($stats.Count)" -ForegroundColor Gray
        Write-Host "    Dimensione: $($sizeGB.ToString('F2')) GB" -ForegroundColor Gray
    }
}

# ═══════════════════════════════════════════════════════════════════
#  MAIN EXECUTION
# ═══════════════════════════════════════════════════════════════════

Clear-Host

Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║       GENE1799 INTELLIGENT FILE MANAGER - v1.0.0         ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

switch ($Mode) {
    'ORGANIZE' {
        Start-IntelligentOrganization -SourcePath $TargetPath -DryRun:$DryRun
    }
    
    'ANALYZE' {
        Get-FileStatistics -Path $TargetPath
    }
    
    'CLEANUP' {
        Start-CleanupOperation -Path $TargetPath
    }
    
    'BACKUP' {
        Start-BackupOperation -SourcePath $TargetPath
    }
    
    'AUTO' {
        Write-Host "🤖 Modalità Automatica Attivata" -ForegroundColor Magenta
        Write-Host "Eseguo tutte le operazioni in sequenza...`n" -ForegroundColor Gray
        
        Get-FileStatistics -Path $TargetPath
        Start-IntelligentOrganization -SourcePath $TargetPath -DryRun:$DryRun
        Start-CleanupOperation -Path $TargetPath
        
        Write-Host "`n✅ Operazioni automatiche completate!" -ForegroundColor Green
    }
    
    'STATUS' {
        Get-FileStatistics -Path $TargetPath
    }
}
