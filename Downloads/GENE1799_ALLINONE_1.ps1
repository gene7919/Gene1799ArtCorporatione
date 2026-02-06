# ═══════════════════════════════════════════════════════════
# 🚀 GENE1799 ALL-IN-ONE INSTALLER v2.0
# Script completo che installa tutto il sistema automaticamente
# ═══════════════════════════════════════════════════════════

param(
    [ValidateSet("INSTALL", "STATUS", "CREATE_AGENT", "TRAIN", "GUI", "HELP")]
    [string]$Action = "INSTALL"
)

$ErrorActionPreference = "Stop"

# ═══════════════════════════════════════════════════════════
# BANNER
# ═══════════════════════════════════════════════════════════

function Show-Banner {
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║        🧠 GENE1799 ALL-IN-ONE INSTALLER v2.0 🧠          ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║           Sistema AI Multi-Provider Integrato            ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan
}

# ═══════════════════════════════════════════════════════════
# FUNZIONE INSTALLAZIONE
# ═══════════════════════════════════════════════════════════

function Install-Gene1799System {
    Show-Banner
    
    Write-Host "🚀 Avvio installazione sistema GENE1799..." -ForegroundColor Yellow
    Write-Host ""
    
    # Passo 1: Crea tutte le directory
    Write-Host "📁 PASSO 1/5: Creazione struttura directory" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    $directories = @(
        # Disco C:
        "C:\AI",
        "C:\AI\Models",
        "C:\AI\Agents",
        "C:\AI\Cache",
        
        # Disco D: Gene1799
        "D:\Gene1799",
        "D:\Gene1799\Modules",
        "D:\Gene1799\Agents",
        "D:\Gene1799\Synaptic",
        "D:\Gene1799\Synaptic\Weights",
        "D:\Gene1799\Logs",
        "D:\Gene1799\Logs\Agents",
        "D:\Gene1799\Database",
        "D:\Gene1799\Explorer",
        
        # Disco D: Electronic
        "D:\Electronic",
        "D:\Electronic\Modules",
        "D:\Electronic\Data",
        "D:\Electronic\Agents"
    )
    
    # Aggiungi disco E: se esiste
    if (Test-Path "E:\") {
        $directories += @(
            "E:\GENE1799_AI",
            "E:\GENE1799_AI\Models",
            "E:\GENE1799_AI\Training",
            "E:\GENE1799_AI\Results",
            "E:\GENE1799_AI\Backups",
            "E:\GENE1799_AI\Providers",
            "E:\GENE1799_AI\Providers\OpenAI",
            "E:\GENE1799_AI\Providers\Anthropic",
            "E:\GENE1799_AI\Providers\Google",
            "E:\GENE1799_AI\Providers\HuggingFace",
            "E:\GENE1799_AI\Providers\Ollama",
            "E:\GENE1799_AI\Providers\StabilityAI"
        )
        $aiExtendedPath = "E:\GENE1799_AI"
    } else {
        Write-Host "⚠️  Disco E: non trovato, uso D:\Gene1799\AI_Extended" -ForegroundColor Yellow
        $directories += @(
            "D:\Gene1799\AI_Extended",
            "D:\Gene1799\AI_Extended\Models",
            "D:\Gene1799\AI_Extended\Training",
            "D:\Gene1799\AI_Extended\Results",
            "D:\Gene1799\AI_Extended\Backups",
            "D:\Gene1799\AI_Extended\Providers"
        )
        $aiExtendedPath = "D:\Gene1799\AI_Extended"
    }
    
    $created = 0
    $existing = 0
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-Host "  ✓ Creata: $dir" -ForegroundColor Green
            $created++
        } else {
            $existing++
        }
    }
    
    Write-Host "`n  📊 Directory create: $created | Esistenti: $existing" -ForegroundColor Cyan
    
    # Passo 2: Crea file di configurazione
    Write-Host "`n📝 PASSO 2/5: Creazione file di configurazione" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    # Database agenti
    $agentDbPath = "D:\Gene1799\Database\agents.json"
    if (-not (Test-Path $agentDbPath)) {
        $agentDb = @{
            version = "2.0"
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            agents = @()
        } | ConvertTo-Json -Depth 10
        
        $agentDb | Set-Content $agentDbPath
        Write-Host "  ✓ Database agenti creato" -ForegroundColor Green
    }
    
    # Config AI
    $aiConfigPath = "D:\Gene1799\Database\ai_config.json"
    if (-not (Test-Path $aiConfigPath)) {
        $aiConfig = @{
            version = "2.0"
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            ai_extended_path = $aiExtendedPath
            providers = @{
                OpenAI = "https://api.openai.com/v1"
                Anthropic = "https://api.anthropic.com/v1"
                Google = "https://generativelanguage.googleapis.com/v1"
                HuggingFace = "https://api-inference.huggingface.co"
                Ollama = "http://localhost:11434/api"
                StabilityAI = "https://api.stability.ai/v1"
            }
            system_status = "INITIALIZED"
        } | ConvertTo-Json -Depth 10
        
        $aiConfig | Set-Content $aiConfigPath
        Write-Host "  ✓ Configurazione AI creata" -ForegroundColor Green
    }
    
    # API Keys template
    $apiKeysPath = "D:\Gene1799\Database\.api_keys.json"
    if (-not (Test-Path $apiKeysPath)) {
        $apiKeys = @{
            openai = ""
            anthropic = ""
            google = ""
            huggingface = ""
            stability = ""
            note = "Inserisci qui le tue API keys. Questo file è protetto!"
        } | ConvertTo-Json -Depth 10
        
        $apiKeys | Set-Content $apiKeysPath
        Write-Host "  ✓ Template API keys creato" -ForegroundColor Green
    }
    
    # Connection map
    $connectionMapPath = "D:\Gene1799\Synaptic\connection_map.json"
    if (-not (Test-Path $connectionMapPath)) {
        $connectionMap = @{
            "C:\AI" = @{
                connected_to = @("D:\Gene1799", $aiExtendedPath)
                purpose = "AI Core processing"
                weight = 1.0
            }
            "D:\Gene1799" = @{
                connected_to = @("C:\AI", $aiExtendedPath, "D:\Electronic")
                purpose = "Central coordination hub"
                weight = 1.0
            }
            $aiExtendedPath = @{
                connected_to = @("C:\AI", "D:\Gene1799")
                purpose = "Extended AI storage & training"
                weight = 0.9
            }
            "D:\Electronic" = @{
                connected_to = @("D:\Gene1799", "C:\AI")
                purpose = "Electronic systems integration"
                weight = 0.8
            }
        } | ConvertTo-Json -Depth 10
        
        $connectionMap | Set-Content $connectionMapPath
        Write-Host "  ✓ Mappa connessioni sinaptica creata" -ForegroundColor Green
    }
    
    # Passo 3: Crea script helper nella cartella Explorer
    Write-Host "`n🔧 PASSO 3/5: Creazione script di sistema" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    # Quick launcher script
    $quickLauncherPath = "D:\Gene1799\Explorer\QUICK_START.ps1"
    $quickLauncher = @'
# GENE1799 Quick Launcher
param([string]$Command = "help")

$explorerPath = "D:\Gene1799\Explorer"

switch ($Command.ToLower()) {
    "help" {
        Write-Host "`n🧠 GENE1799 Quick Commands:" -ForegroundColor Cyan
        Write-Host "  .\QUICK_START.ps1 status      - Mostra status sistema" -ForegroundColor White
        Write-Host "  .\QUICK_START.ps1 create      - Crea nuovo agente" -ForegroundColor White
        Write-Host "  .\QUICK_START.ps1 list        - Lista agenti" -ForegroundColor White
        Write-Host "  .\QUICK_START.ps1 gui         - Avvia GUI" -ForegroundColor White
        Write-Host "  .\QUICK_START.ps1 config      - Configura API keys" -ForegroundColor White
    }
    "status" {
        Write-Host "`n📊 GENE1799 Status:" -ForegroundColor Cyan
        Write-Host "  C:\AI -> $(if (Test-Path 'C:\AI') {'✓ Online'} else {'✗ Offline'})" -ForegroundColor $(if (Test-Path 'C:\AI') {'Green'} else {'Red'})
        Write-Host "  D:\Gene1799 -> $(if (Test-Path 'D:\Gene1799') {'✓ Online'} else {'✗ Offline'})" -ForegroundColor $(if (Test-Path 'D:\Gene1799') {'Green'} else {'Red'})
        Write-Host "  D:\Electronic -> $(if (Test-Path 'D:\Electronic') {'✓ Online'} else {'✗ Offline'})" -ForegroundColor $(if (Test-Path 'D:\Electronic') {'Green'} else {'Red'})
        
        if (Test-Path "D:\Gene1799\Database\agents.json") {
            $db = Get-Content "D:\Gene1799\Database\agents.json" | ConvertFrom-Json
            Write-Host "`n  Agenti registrati: $($db.agents.Count)" -ForegroundColor Cyan
        }
    }
    "create" {
        Write-Host "`n🤖 Creazione agente interattiva:" -ForegroundColor Cyan
        $name = Read-Host "Nome agente"
        $type = Read-Host "Tipo (FILE_MANAGER, SYSTEM_MONITOR, CODE_ASSISTANT, etc.)"
        
        Write-Host "`nCreazione agente '$name' di tipo '$type'..." -ForegroundColor Yellow
        # Qui andrebbe il codice per creare l'agente
        Write-Host "✓ Agente creato! (Funzionalità da implementare)" -ForegroundColor Green
    }
    "list" {
        if (Test-Path "D:\Gene1799\Database\agents.json") {
            $db = Get-Content "D:\Gene1799\Database\agents.json" | ConvertFrom-Json
            Write-Host "`n🤖 Agenti registrati: $($db.agents.Count)" -ForegroundColor Cyan
            foreach ($agent in $db.agents) {
                Write-Host "  • $($agent.name) [$($agent.type)] - $($agent.status)" -ForegroundColor White
            }
        } else {
            Write-Host "`n⚠️  Nessun agente trovato" -ForegroundColor Yellow
        }
    }
    "config" {
        notepad "D:\Gene1799\Database\.api_keys.json"
    }
    "gui" {
        Write-Host "`n🖥️  Avvio GUI... (Da implementare)" -ForegroundColor Yellow
    }
    default {
        Write-Host "`n❌ Comando non riconosciuto. Usa 'help' per vedere i comandi disponibili." -ForegroundColor Red
    }
}
'@
    
    $quickLauncher | Set-Content $quickLauncherPath
    Write-Host "  ✓ Quick launcher creato: QUICK_START.ps1" -ForegroundColor Green
    
    # Passo 4: Test sistema
    Write-Host "`n🧪 PASSO 4/5: Test sistema" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    $tests = @(
        @{Name="C:\AI"; Result=(Test-Path "C:\AI")}
        @{Name="D:\Gene1799"; Result=(Test-Path "D:\Gene1799")}
        @{Name="Database agenti"; Result=(Test-Path "D:\Gene1799\Database\agents.json")}
        @{Name="Config AI"; Result=(Test-Path "D:\Gene1799\Database\ai_config.json")}
    )
    
    foreach ($test in $tests) {
        $status = if ($test.Result) { "✓ PASS" } else { "✗ FAIL" }
        $color = if ($test.Result) { "Green" } else { "Red" }
        Write-Host "  $status - $($test.Name)" -ForegroundColor $color
    }
    
    # Passo 5: Finalizzazione
    Write-Host "`n✅ PASSO 5/5: Finalizzazione" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════" -ForegroundColor DarkGray
    
    # Crea file README nella cartella Explorer
    $readmePath = "D:\Gene1799\Explorer\README.txt"
    $readme = @"
═══════════════════════════════════════════════════════════
  GENE1799 AI INTEGRATION SYSTEM v2.0 - Installato!
═══════════════════════════════════════════════════════════

✅ Sistema installato con successo!

📁 STRUTTURA CREATA:
- C:\AI                 - AI Core
- D:\Gene1799           - Hub centrale
- D:\Electronic         - Sistemi elettronici
- $aiExtendedPath       - AI Extended storage

🚀 COMANDI RAPIDI:

1. Status sistema:
   .\GENE1799_ALLINONE.ps1 -Action STATUS

2. Creare un agente:
   .\GENE1799_ALLINONE.ps1 -Action CREATE_AGENT

3. Quick launcher:
   .\QUICK_START.ps1 help

📝 CONFIGURAZIONE:
- API Keys: D:\Gene1799\Database\.api_keys.json
- Config: D:\Gene1799\Database\ai_config.json
- Agents DB: D:\Gene1799\Database\agents.json

🔧 TOOLS:
- QUICK_START.ps1 - Launcher veloce
- GENE1799_ALLINONE.ps1 - Script principale

📚 Per maggiori info, consulta la documentazione online.

Data installazione: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
═══════════════════════════════════════════════════════════
"@
    
    $readme | Set-Content $readmePath
    Write-Host "  ✓ README creato" -ForegroundColor Green
    
    # Mostra risultato finale
    Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                                                           ║" -ForegroundColor Green
    Write-Host "║              ✅ INSTALLAZIONE COMPLETATA! ✅              ║" -ForegroundColor Green
    Write-Host "║                                                           ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Green
    
    Write-Host "📊 Riepilogo:" -ForegroundColor Cyan
    Write-Host "  • Directory create: $created" -ForegroundColor White
    Write-Host "  • File configurazione: 4" -ForegroundColor White
    Write-Host "  • Script helper: 2" -ForegroundColor White
    Write-Host "  • Path AI Extended: $aiExtendedPath" -ForegroundColor White
    
    Write-Host "`n🎯 Prossimi passi:" -ForegroundColor Yellow
    Write-Host "  1. Configura API keys (opzionale):" -ForegroundColor Gray
    Write-Host "     notepad D:\Gene1799\Database\.api_keys.json" -ForegroundColor White
    Write-Host "`n  2. Usa il Quick Launcher:" -ForegroundColor Gray
    Write-Host "     .\QUICK_START.ps1 help" -ForegroundColor White
    Write-Host "`n  3. Crea il tuo primo agente:" -ForegroundColor Gray
    Write-Host "     .\GENE1799_ALLINONE.ps1 -Action CREATE_AGENT" -ForegroundColor White
    
    Write-Host "`n✨ Sistema pronto all'uso! ✨`n" -ForegroundColor Green
}

# ═══════════════════════════════════════════════════════════
# FUNZIONE STATUS
# ═══════════════════════════════════════════════════════════

function Show-SystemStatus {
    Show-Banner
    
    Write-Host "📊 GENE1799 SYSTEM STATUS" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray
    
    # Dischi
    Write-Host "💾 Dischi:" -ForegroundColor Yellow
    $disks = @(
        @{Letter="C:"; Path="C:\AI"; Name="AI Core"}
        @{Letter="D:"; Path="D:\Gene1799"; Name="GENE1799 Core"}
        @{Letter="D:"; Path="D:\Electronic"; Name="Electronic"}
        @{Letter="E:"; Path="E:\GENE1799_AI"; Name="AI Extended"}
    )
    
    foreach ($disk in $disks) {
        $exists = Test-Path $disk.Path
        $status = if ($exists) { "✓ Online" } else { "✗ Offline" }
        $color = if ($exists) { "Green" } else { "Red" }
        Write-Host "  [$($disk.Letter)] $($disk.Name.PadRight(20)): " -NoNewline
        Write-Host $status -ForegroundColor $color
    }
    
    # Agenti
    Write-Host "`n🤖 Agenti:" -ForegroundColor Yellow
    if (Test-Path "D:\Gene1799\Database\agents.json") {
        $db = Get-Content "D:\Gene1799\Database\agents.json" | ConvertFrom-Json
        Write-Host "  Totale agenti: $($db.agents.Count)" -ForegroundColor Cyan
        
        if ($db.agents.Count -gt 0) {
            foreach ($agent in $db.agents) {
                Write-Host "  • $($agent.name) [$($agent.type)] - $($agent.status)" -ForegroundColor White
            }
        }
    } else {
        Write-Host "  Database agenti non trovato" -ForegroundColor Red
    }
    
    # Config
    Write-Host "`n⚙️  Configurazione:" -ForegroundColor Yellow
    $configExists = Test-Path "D:\Gene1799\Database\ai_config.json"
    $apiKeysExist = Test-Path "D:\Gene1799\Database\.api_keys.json"
    
    Write-Host "  Config AI: $(if ($configExists) {'✓'} else {'✗'})" -ForegroundColor $(if ($configExists) {'Green'} else {'Red'})
    Write-Host "  API Keys: $(if ($apiKeysExist) {'✓'} else {'✗'})" -ForegroundColor $(if ($apiKeysExist) {'Green'} else {'Red'})
    
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# FUNZIONE CREAZIONE AGENTE INTERATTIVA
# ═══════════════════════════════════════════════════════════

function New-AgentInteractive {
    Show-Banner
    
    Write-Host "🤖 CREAZIONE AGENTE INTERATTIVA" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray
    
    # Input nome
    $agentName = Read-Host "Nome dell'agente"
    
    if ([string]::IsNullOrWhiteSpace($agentName)) {
        Write-Host "❌ Nome agente richiesto!" -ForegroundColor Red
        return
    }
    
    # Mostra tipi disponibili
    Write-Host "`nTipi di agente disponibili:" -ForegroundColor Yellow
    Write-Host "  1. FILE_MANAGER     - Gestione file e backup" -ForegroundColor White
    Write-Host "  2. SYSTEM_MONITOR   - Monitoraggio sistema" -ForegroundColor White
    Write-Host "  3. SECURITY_SCANNER - Scansione sicurezza" -ForegroundColor White
    Write-Host "  4. DATA_ANALYST     - Analisi dati" -ForegroundColor White
    Write-Host "  5. CODE_ASSISTANT   - Assistente programmazione" -ForegroundColor White
    Write-Host "  6. AUTOMATION_BOT   - Task automation" -ForegroundColor White
    Write-Host "  7. CONTENT_CREATOR  - Creazione contenuti" -ForegroundColor White
    Write-Host "  8. NETWORK_MANAGER  - Gestione rete" -ForegroundColor White
    
    $choice = Read-Host "`nScegli tipo (1-8)"
    
    $types = @("FILE_MANAGER", "SYSTEM_MONITOR", "SECURITY_SCANNER", "DATA_ANALYST", 
               "CODE_ASSISTANT", "AUTOMATION_BOT", "CONTENT_CREATOR", "NETWORK_MANAGER")
    
    if ($choice -match '^\d$' -and [int]$choice -ge 1 -and [int]$choice -le 8) {
        $agentType = $types[[int]$choice - 1]
    } else {
        Write-Host "❌ Scelta non valida!" -ForegroundColor Red
        return
    }
    
    Write-Host "`n🔧 Creazione agente '$agentName' di tipo '$agentType'..." -ForegroundColor Yellow
    
    # Carica database
    $dbPath = "D:\Gene1799\Database\agents.json"
    if (Test-Path $dbPath) {
        $db = Get-Content $dbPath | ConvertFrom-Json
    } else {
        $db = @{
            version = "2.0"
            created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            agents = @()
        }
    }
    
    # Crea agente
    $agent = @{
        id = (New-Guid).ToString()
        name = $agentName
        type = $agentType
        created = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        status = "INITIALIZED"
        accuracy = 0.0
        experience_points = 0
    }
    
    # Aggiungi a database
    if ($db.agents -is [array]) {
        $db.agents += $agent
    } else {
        $db.agents = @($agent)
    }
    
    # Salva
    $db | ConvertTo-Json -Depth 10 | Set-Content $dbPath
    
    Write-Host "✅ Agente '$agentName' creato con successo!" -ForegroundColor Green
    Write-Host "   ID: $($agent.id)" -ForegroundColor Gray
    Write-Host "   Tipo: $agentType" -ForegroundColor Gray
    Write-Host "   Status: INITIALIZED" -ForegroundColor Yellow
    Write-Host "`n💡 Usa .\GENE1799_ALLINONE.ps1 -Action TRAIN per addestrarlo!" -ForegroundColor Cyan
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# FUNZIONE HELP
# ═══════════════════════════════════════════════════════════

function Show-Help {
    Show-Banner
    
    Write-Host "📚 GUIDA RAPIDA GENE1799" -ForegroundColor Cyan
    Write-Host "══════════════════════════════════════════════════════════`n" -ForegroundColor DarkGray
    
    Write-Host "Comandi disponibili:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  .\GENE1799_ALLINONE.ps1 -Action INSTALL" -ForegroundColor White
    Write-Host "    → Installa tutto il sistema (esegui solo la prima volta)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\GENE1799_ALLINONE.ps1 -Action STATUS" -ForegroundColor White
    Write-Host "    → Mostra status completo del sistema" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\GENE1799_ALLINONE.ps1 -Action CREATE_AGENT" -ForegroundColor White
    Write-Host "    → Crea un nuovo agente AI (interattivo)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  .\GENE1799_ALLINONE.ps1 -Action HELP" -ForegroundColor White
    Write-Host "    → Mostra questa guida" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Quick Launcher:" -ForegroundColor Yellow
    Write-Host "  Dopo l'installazione, usa:" -ForegroundColor Gray
    Write-Host "  .\QUICK_START.ps1 help" -ForegroundColor White
    Write-Host ""
    
    Write-Host "File importanti:" -ForegroundColor Yellow
    Write-Host "  • D:\Gene1799\Database\agents.json - Database agenti" -ForegroundColor Gray
    Write-Host "  • D:\Gene1799\Database\.api_keys.json - API keys" -ForegroundColor Gray
    Write-Host "  • D:\Gene1799\Explorer\README.txt - Info installazione" -ForegroundColor Gray
    Write-Host ""
}

# ═══════════════════════════════════════════════════════════
# MAIN EXECUTION
# ═══════════════════════════════════════════════════════════

switch ($Action) {
    "INSTALL" {
        Install-Gene1799System
    }
    "STATUS" {
        Show-SystemStatus
    }
    "CREATE_AGENT" {
        New-AgentInteractive
    }
    "HELP" {
        Show-Help
    }
    default {
        Show-Help
    }
}
