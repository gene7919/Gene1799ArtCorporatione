$ErrorActionPreference = "Stop"

$root = "C:\SuiteV17\SocialHubV1"

function W {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    Set-Content -Path $Path -Value $Content -Encoding UTF8
}

$dirs = @(
    $root,
    "$root\modules",
    "$root\publishers",
    "$root\config",
    "$root\output",
    "$root\output\history",
    "$root\logs",
    "$root\queue",
    "$root\queue\pending",
    "$root\queue\published"
)

foreach ($d in $dirs) {
    New-Item -ItemType Directory -Path $d -Force | Out-Null
}

$appSettings = @"
{
  "app": {
    "name": "SuiteV17 SocialHub",
    "version": "1.0.0"
  },
  "groq": {
    "modelFallback": [
      "llama-3.3-70b-versatile",
      "llama-3.1-8b-instant"
    ],
    "temperature": 0.7,
    "maxRetries": 3
  },
  "publish": {
    "defaultPlatforms": [
      "instagram",
      "facebook",
      "x",
      "tiktok"
    ],
    "requireApproval": true,
    "autoPublish": false
  },
  "prompts": {
    "default": "Scrivi un post social in italiano su Gene1799artcorporatione. Usa solo elementi certi: arte digitale, NFT, processo creativo ibrido tra manuale, digitale e AI, identita artistica forte, innovazione visiva. Non inventare collaborazioni, premi, sostenibilita, eventi o dati non forniti. Tono elegante e potente. Massimo 120 parole. Chiudi con 5 hashtag pertinenti."
  }
}
"@

$common = @"
Set-StrictMode -Version Latest

function Set-Utf8Console {
    try { chcp 65001 > `$null } catch {}
    try { [Console]::InputEncoding  = [System.Text.UTF8Encoding]::new() } catch {}
    try { [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new() } catch {}
    try { `$global:OutputEncoding   = [System.Text.UTF8Encoding]::new() } catch {}
}

function Initialize-SocialHub {
    param([Parameter(Mandatory=`$true)][string]`$RootDir)

    `$paths = @(
        (Join-Path `$RootDir "logs"),
        (Join-Path `$RootDir "output"),
        (Join-Path `$RootDir "output\history"),
        (Join-Path `$RootDir "queue"),
        (Join-Path `$RootDir "queue\pending"),
        (Join-Path `$RootDir "queue\published"),
        (Join-Path `$RootDir "config"),
        (Join-Path `$RootDir "modules"),
        (Join-Path `$RootDir "publishers")
    )

    foreach (`$p in `$paths) {
        New-Item -ItemType Directory -Path `$p -Force | Out-Null
    }
}

function Get-TimeStamp {
    return (Get-Date -Format "yyyyMMdd_HHmmss")
}

function Write-Log {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)][string]`$Message,
        [ValidateSet("INFO","WARN","ERROR","OK")][string]`$Level = "INFO"
    )

    `$logFile = Join-Path `$RootDir ("logs\socialhub_{0}.log" -f (Get-Date -Format "yyyyMMdd"))
    `$line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), `$Level, `$Message
    Add-Content -Path `$logFile -Value `$line -Encoding UTF8

    switch (`$Level) {
        "INFO"  { Write-Host `$line -ForegroundColor Cyan }
        "WARN"  { Write-Host `$line -ForegroundColor Yellow }
        "ERROR" { Write-Host `$line -ForegroundColor Red }
        "OK"    { Write-Host `$line -ForegroundColor Green }
    }
}

function Read-AppSettings {
    param([Parameter(Mandatory=`$true)][string]`$RootDir)

    `$path = Join-Path `$RootDir "config\appsettings.json"
    if (-not (Test-Path `$path)) {
        throw "Configurazione non trovata: `$path"
    }

    return (Get-Content -Path `$path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Save-AppSettings {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)]`$Settings
    )

    `$path = Join-Path `$RootDir "config\appsettings.json"
    (`$Settings | ConvertTo-Json -Depth 20) | Set-Content -Path `$path -Encoding UTF8
}

function ConvertTo-PlainText {
    param([Parameter(Mandatory=`$true)][Security.SecureString]`$SecureString)

    `$bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR(`$SecureString)
    try {
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR(`$bstr)
    }
    finally {
        if (`$bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR(`$bstr)
        }
    }
}

function Get-SecretBaseDir {
    `$dir = Join-Path `$env:USERPROFILE ".suitev17"
    New-Item -ItemType Directory -Path `$dir -Force | Out-Null
    return `$dir
}

function Get-SecretPath {
    param([Parameter(Mandatory=`$true)][string]`$Name)
    Join-Path (Get-SecretBaseDir) ("{0}.secure" -f `$Name)
}

function Save-EncryptedSecret {
    param(
        [Parameter(Mandatory=`$true)][string]`$Name,
        [Parameter(Mandatory=`$true)][string]`$Value
    )

    `$secure = ConvertTo-SecureString -String `$Value -AsPlainText -Force
    `$encrypted = `$secure | ConvertFrom-SecureString
    `$path = Get-SecretPath -Name `$Name
    Set-Content -Path `$path -Value `$encrypted -Encoding UTF8
}

function Get-EncryptedSecret {
    param([Parameter(Mandatory=`$true)][string]`$Name)

    `$path = Get-SecretPath -Name `$Name
    if (-not (Test-Path `$path)) { return `$null }

    try {
        `$encrypted = Get-Content -Path `$path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace(`$encrypted)) { return `$null }
        `$secure = `$encrypted | ConvertTo-SecureString
        return (ConvertTo-PlainText -SecureString `$secure)
    }
    catch {
        return `$null
    }
}

function Get-GroqApiKey {
    if (`$env:GROQ_API_KEY -and `$env:GROQ_API_KEY.Trim().StartsWith("gsk_")) {
        return `$env:GROQ_API_KEY.Trim()
    }

    `$saved = Get-EncryptedSecret -Name "groq_api_key"
    if (`$saved -and `$saved.Trim().StartsWith("gsk_")) {
        return `$saved.Trim()
    }

    Write-Host "Chiave API Groq non trovata." -ForegroundColor Yellow
    `$secureInput = Read-Host "Incolla la tua chiave Groq" -AsSecureString
    `$plain = (ConvertTo-PlainText -SecureString `$secureInput).Trim()

    if (-not `$plain.StartsWith("gsk_")) {
        throw "La chiave Groq non sembra valida."
    }

    Save-EncryptedSecret -Name "groq_api_key" -Value `$plain
    return `$plain
}

function Get-N8nWebhookUrl {
    if (`$env:N8N_SUITEV17_WEBHOOK -and `$env:N8N_SUITEV17_WEBHOOK.Trim().StartsWith("http")) {
        return `$env:N8N_SUITEV17_WEBHOOK.Trim()
    }

    `$saved = Get-EncryptedSecret -Name "n8n_suitev17_webhook"
    if (`$saved -and `$saved.Trim().StartsWith("http")) {
        return `$saved.Trim()
    }

    return `$null
}

function Set-N8nWebhookUrl {
    param([Parameter(Mandatory=`$true)][string]`$Url)
    Save-EncryptedSecret -Name "n8n_suitev17_webhook" -Value `$Url.Trim()
}

function Get-HttpErrorInfo {
    param([Parameter(Mandatory=`$true)]`$ErrorRecord)

    `$statusCode = `$null
    `$body = `$null
    `$message = `$ErrorRecord.Exception.Message

    try {
        if (`$ErrorRecord.Exception.Response -and `$ErrorRecord.Exception.Response.StatusCode) {
            `$statusCode = [int]`$ErrorRecord.Exception.Response.StatusCode
        }
    } catch {}

    try {
        if (`$ErrorRecord.ErrorDetails -and `$ErrorRecord.ErrorDetails.Message) {
            `$body = `$ErrorRecord.ErrorDetails.Message
        }
    } catch {}

    if (-not `$body) { `$body = `$message }

    [PSCustomObject]@{
        StatusCode = `$statusCode
        Body       = `$body
        Message    = `$message
    }
}

function Save-PostFiles {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)]`$PostObject
    )

    `$txtPath = Join-Path `$RootDir "output\latest_post.txt"
    `$jsonPath = Join-Path `$RootDir "output\latest_post.json"
    `$historyPath = Join-Path `$RootDir ("output\history\post_{0}.json" -f (Get-TimeStamp))

    Set-Content -Path `$txtPath -Value `$PostObject.content -Encoding UTF8
    (`$PostObject | ConvertTo-Json -Depth 20) | Set-Content -Path `$jsonPath -Encoding UTF8
    (`$PostObject | ConvertTo-Json -Depth 20) | Set-Content -Path `$historyPath -Encoding UTF8

    [PSCustomObject]@{
        TextPath    = `$txtPath
        JsonPath    = `$jsonPath
        HistoryPath = `$historyPath
    }
}

function Queue-Payload {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)]`$PayloadObject
    )

    `$path = Join-Path `$RootDir ("queue\pending\payload_{0}.json" -f (Get-TimeStamp))
    (`$PayloadObject | ConvertTo-Json -Depth 25) | Set-Content -Path `$path -Encoding UTF8
    return `$path
}

function Mark-PayloadPublished {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)][string]`$PendingPath
    )

    if (-not (Test-Path `$PendingPath)) { return `$null }

    `$dest = Join-Path `$RootDir ("queue\published\{0}" -f (Split-Path -Leaf `$PendingPath))
    Move-Item -Path `$PendingPath -Destination `$dest -Force
    return `$dest
}
"@

$groqClient = @"
Set-StrictMode -Version Latest

function Invoke-GroqRaw {
    param(
        [Parameter(Mandatory=`$true)][string]`$ApiKey,
        [Parameter(Mandatory=`$true)][string]`$Prompt,
        [Parameter(Mandatory=`$true)][string]`$Model,
        [double]`$Temperature = 0.7
    )

    `$headers = @{
        Authorization = "Bearer `$ApiKey"
    }

    `$body = @{
        model = `$Model
        messages = @(
            @{
                role = "user"
                content = `$Prompt
            }
        )
        temperature = `$Temperature
    } | ConvertTo-Json -Depth 10

    Invoke-RestMethod `
        -Uri "https://api.groq.com/openai/v1/chat/completions" `
        -Method Post `
        -Headers `$headers `
        -ContentType "application/json; charset=utf-8" `
        -Body `$body
}

function Invoke-GroqWithRetry {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)][string]`$ApiKey,
        [Parameter(Mandatory=`$true)][string]`$Prompt,
        [Parameter(Mandatory=`$true)][string]`$Model,
        [double]`$Temperature = 0.7,
        [int]`$Retries = 3
    )

    for (`$attempt = 1; `$attempt -le `$Retries; `$attempt++) {
        try {
            Write-Log -RootDir `$RootDir -Message ("Groq tentativo {0}/{1} sul modello {2}" -f `$attempt, `$Retries, `$Model) -Level "INFO"
            return (Invoke-GroqRaw -ApiKey `$ApiKey -Prompt `$Prompt -Model `$Model -Temperature `$Temperature)
        }
        catch {
            `$err = Get-HttpErrorInfo -ErrorRecord `$_

            if (`$err.StatusCode -eq 401) {
                throw "ERRORE GROQ 401 Unauthorized. Chiave non valida o revocata."
            }

            `$transient = `$err.StatusCode -in 408,429,500,502,503,504
            if (`$transient -and `$attempt -lt `$Retries) {
                `$sleepSec = [Math]::Min(10, [Math]::Pow(2, `$attempt))
                Write-Log -RootDir `$RootDir -Message ("Errore temporaneo HTTP {0}. Attendo {1}s." -f `$err.StatusCode, `$sleepSec) -Level "WARN"
                Start-Sleep -Seconds `$sleepSec
                continue
            }

            throw ("Groq fallita. HTTP {0}. Dettagli: {1}" -f `$err.StatusCode, `$err.Body)
        }
    }

    throw "Groq fallita dopo tutti i retry."
}

function Invoke-GroqText {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)][string]`$Prompt,
        [Parameter(Mandatory=`$true)]`$Settings
    )

    `$apiKey = Get-GroqApiKey
    `$models = @(`$Settings.groq.modelFallback)
    if (-not `$models -or `$models.Count -eq 0) {
        `$models = @("llama-3.3-70b-versatile","llama-3.1-8b-instant")
    }

    `$temperature = 0.7
    if (`$Settings.groq.temperature -ne `$null) {
        `$temperature = [double]`$Settings.groq.temperature
    }

    `$retries = 3
    if (`$Settings.groq.maxRetries -ne `$null) {
        `$retries = [int]`$Settings.groq.maxRetries
    }

    `$lastError = `$null

    foreach (`$model in `$models) {
        try {
            `$resp = Invoke-GroqWithRetry -RootDir `$RootDir -ApiKey `$apiKey -Prompt `$Prompt -Model `$model -Temperature `$temperature -Retries `$retries
            `$content = `$resp.choices[0].message.content

            if ([string]::IsNullOrWhiteSpace(`$content)) {
                throw "Risposta vuota."
            }

            return [PSCustomObject]@{
                createdAt = (Get-Date).ToString("s")
                model     = `$model
                prompt    = `$Prompt
                content   = `$content.Trim()
            }
        }
        catch {
            `$lastError = `$_ .Exception.Message
            Write-Log -RootDir `$RootDir -Message ("Fallback modello {0}: {1}" -f `$model, `$lastError) -Level "WARN"
        }
    }

    throw "Nessun modello Groq ha funzionato. Ultimo errore: `$lastError"
}
"@

$n8nPublisher = @"
Set-StrictMode -Version Latest

function Get-MimeType {
    param([string]`$Path)

    `$ext = ([IO.Path]::GetExtension(`$Path)).ToLowerInvariant()
    switch (`$ext) {
        ".jpg"  { "image/jpeg" }
        ".jpeg" { "image/jpeg" }
        ".png"  { "image/png" }
        ".webp" { "image/webp" }
        ".gif"  { "image/gif" }
        default { "application/octet-stream" }
    }
}

function New-ImagePayload {
    param([string]`$ImagePath)

    if ([string]::IsNullOrWhiteSpace(`$ImagePath)) { return `$null }
    if (-not (Test-Path `$ImagePath)) { throw "Immagine non trovata: `$ImagePath" }

    `$resolved = (Resolve-Path `$ImagePath).Path
    `$bytes = [System.IO.File]::ReadAllBytes(`$resolved)

    [PSCustomObject]@{
        fileName      = [IO.Path]::GetFileName(`$resolved)
        mimeType      = (Get-MimeType -Path `$resolved)
        contentBase64 = [Convert]::ToBase64String(`$bytes)
    }
}

function Invoke-N8nPublish {
    param(
        [Parameter(Mandatory=`$true)][string]`$RootDir,
        [Parameter(Mandatory=`$true)]`$PostObject,
        [Parameter(Mandatory=`$true)]`$Settings,
        [string]`$ImagePath = "",
        [string[]]`$Platforms = @(),
        [switch]`$TestMode
    )

    `$url = Get-N8nWebhookUrl
    if ([string]::IsNullOrWhiteSpace(`$url)) {
        throw "Webhook n8n non configurato. Esegui prima .\Configure-SocialHub.ps1"
    }

    if (-not `$Platforms -or `$Platforms.Count -eq 0) {
        `$Platforms = @(`$Settings.publish.defaultPlatforms)
    }

    `$payload = [ordered]@{
        testMode  = [bool]`$TestMode
        source    = `$Settings.app.name
        version   = `$Settings.app.version
        createdAt = (Get-Date).ToString("s")
        platforms = @(`$Platforms)
        post      = [ordered]@{
            caption     = `$PostObject.content
            prompt      = `$PostObject.prompt
            model       = `$PostObject.model
            generatedAt = `$PostObject.createdAt
        }
        image = (New-ImagePayload -ImagePath `$ImagePath)
    }

    Write-Log -RootDir `$RootDir -Message ("Invio payload a n8n per: {0}" -f ((`$Platforms -join ", "))) -Level "INFO"

    `$response = Invoke-RestMethod `
        -Uri `$url `
        -Method Post `
        -ContentType "application/json; charset=utf-8" `
        -Body (`$payload | ConvertTo-Json -Depth 25)

    `$latest = Join-Path `$RootDir "output\latest_publish_response.json"
    `$hist   = Join-Path `$RootDir ("output\history\publish_response_{0}.json" -f (Get-Date -Format "yyyyMMdd_HHmmss"))

    (`$response | ConvertTo-Json -Depth 25) | Set-Content -Path `$latest -Encoding UTF8
    (`$response | ConvertTo-Json -Depth 25) | Set-Content -Path `$hist -Encoding UTF8

    Write-Log -RootDir `$RootDir -Message "n8n ha risposto correttamente." -Level "OK"

    [PSCustomObject]@{
        RequestPayload = `$payload
        Response       = `$response
        LatestResponse = `$latest
        HistoryResponse = `$hist
    }
}
"@

$startScript = @"
[CmdletBinding()]
param(
    [string]`$Prompt = "",
    [string]`$ImagePath = "",
    [string[]]`$Platforms = @(),
    [switch]`$AutoPublish
)

Set-ExecutionPolicy -Scope Process Bypass -Force

. "`$PSScriptRoot\modules\Common.ps1"
. "`$PSScriptRoot\modules\GroqClient.ps1"
. "`$PSScriptRoot\publishers\N8nWebhook.ps1"

Set-Utf8Console
Initialize-SocialHub -RootDir `$PSScriptRoot

try {
    Write-Log -RootDir `$PSScriptRoot -Message "Avvio Start-SocialHub.ps1" -Level "INFO"

    `$settings = Read-AppSettings -RootDir `$PSScriptRoot

    if ([string]::IsNullOrWhiteSpace(`$Prompt)) {
        `$Prompt = `$settings.prompts.default
    }

    if (-not `$Platforms -or `$Platforms.Count -eq 0) {
        `$Platforms = @(`$settings.publish.defaultPlatforms)
    }

    `$post = Invoke-GroqText -RootDir `$PSScriptRoot -Prompt `$Prompt -Settings `$settings
    `$saved = Save-PostFiles -RootDir `$PSScriptRoot -PostObject `$post

    `$queueObj = [PSCustomObject]@{
        queuedAt  = (Get-Date).ToString("s")
        platforms = @(`$Platforms)
        imagePath = `$ImagePath
        post      = `$post
    }

    `$pendingPath = Queue-Payload -RootDir `$PSScriptRoot -PayloadObject `$queueObj

    Write-Host ""
    Write-Host "=== ANTEPRIMA POST ===" -ForegroundColor Green
    Write-Host `$post.content
    Write-Host ""
    Write-Host "Testo:       `$(`$saved.TextPath)" -ForegroundColor DarkGray
    Write-Host "JSON:        `$(`$saved.JsonPath)" -ForegroundColor DarkGray
    Write-Host "In coda:     `$pendingPath" -ForegroundColor DarkGray
    Write-Host "Piattaforme: `$(`$Platforms -join ', ')" -ForegroundColor DarkGray
    if (-not [string]::IsNullOrWhiteSpace(`$ImagePath)) {
        Write-Host "Immagine:    `$ImagePath" -ForegroundColor DarkGray
    }
    Write-Host ""

    `$shouldPublish = `$false
    if (`$AutoPublish -or [bool]`$settings.publish.autoPublish) {
        `$shouldPublish = `$true
    }
    elseif ([bool]`$settings.publish.requireApproval) {
        `$ans = Read-Host "Pubblicare ora su n8n? (S/N)"
        if (`$ans -match '^(s|si|y|yes)$') {
            `$shouldPublish = `$true
        }
    }

    if (`$shouldPublish) {
        `$result = Invoke-N8nPublish -RootDir `$PSScriptRoot -PostObject `$post -Settings `$settings -ImagePath `$ImagePath -Platforms `$Platforms
        `$publishedPath = Mark-PayloadPublished -RootDir `$PSScriptRoot -PendingPath `$pendingPath
        Write-Host "Pubblicato. File spostato in: `$publishedPath" -ForegroundColor Green
        Write-Host "Risposta n8n: `$(`$result.LatestResponse)" -ForegroundColor DarkGray
    }
    else {
        Write-Log -RootDir `$PSScriptRoot -Message "Payload lasciato in pending." -Level "WARN"
        Write-Host "Pubblicazione non eseguita. Il payload e rimasto in queue\pending." -ForegroundColor Yellow
    }

    Write-Log -RootDir `$PSScriptRoot -Message "Flusso completato." -Level "OK"
}
catch {
    Write-Log -RootDir `$PSScriptRoot -Message `$_ .Exception.Message -Level "ERROR"
    throw
}
"@

$runScript = @"
[CmdletBinding()]
param(
    [string]`$Prompt = "",
    [string]`$ImagePath = "",
    [string[]]`$Platforms = @(),
    [switch]`$AutoPublish
)

Set-ExecutionPolicy -Scope Process Bypass -Force
& "`$PSScriptRoot\Start-SocialHub.ps1" -Prompt `$Prompt -ImagePath `$ImagePath -Platforms `$Platforms -AutoPublish:`$AutoPublish
"@

$configureScript = @"
Set-ExecutionPolicy -Scope Process Bypass -Force

. "`$PSScriptRoot\modules\Common.ps1"

Set-Utf8Console
Initialize-SocialHub -RootDir `$PSScriptRoot

`$settings = Read-AppSettings -RootDir `$PSScriptRoot

Write-Host ""
Write-Host "=== CONFIGURAZIONE SOCIAL HUB ===" -ForegroundColor Cyan
Write-Host ""

`$currentWebhook = Get-N8nWebhookUrl
if (`$currentWebhook) {
    Write-Host "Webhook n8n gia presente." -ForegroundColor Green
} else {
    Write-Host "Webhook n8n non ancora configurato." -ForegroundColor Yellow
}

`$newWebhook = Read-Host "Incolla URL webhook n8n (vuoto per lasciare invariato)"
if (-not [string]::IsNullOrWhiteSpace(`$newWebhook)) {
    if (-not `$newWebhook.Trim().StartsWith("http")) {
        throw "Il webhook deve iniziare con http o https."
    }
    Set-N8nWebhookUrl -Url `$newWebhook.Trim()
    Write-Host "Webhook salvato in modo cifrato." -ForegroundColor Green
}

`$platformInput = Read-Host "Piattaforme di default separate da virgola (es. instagram,facebook,x,tiktok)"
if (-not [string]::IsNullOrWhiteSpace(`$platformInput)) {
    `$items = `$platformInput.Split(",") | ForEach-Object { `$_.Trim() } | Where-Object { `$_ }
    `$settings.publish.defaultPlatforms = @(`$items)
}

`$approvalInput = Read-Host "Richiedere approvazione manuale prima di pubblicare? (S/N, vuoto=invariato)"
if (`$approvalInput -match '^(s|si|y|yes)$') {
    `$settings.publish.requireApproval = `$true
}
elseif (`$approvalInput -match '^(n|no)$') {
    `$settings.publish.requireApproval = `$false
}

`$autoPublishInput = Read-Host "Pubblicazione automatica senza domanda? (S/N, vuoto=invariato)"
if (`$autoPublishInput -match '^(s|si|y|yes)$') {
    `$settings.publish.autoPublish = `$true
}
elseif (`$autoPublishInput -match '^(n|no)$') {
    `$settings.publish.autoPublish = `$false
}

`$newPrompt = Read-Host "Nuovo prompt di default (vuoto=invariato)"
if (-not [string]::IsNullOrWhiteSpace(`$newPrompt)) {
    `$settings.prompts.default = `$newPrompt
}

Save-AppSettings -RootDir `$PSScriptRoot -Settings `$settings

Write-Host ""
Write-Host "Configurazione salvata." -ForegroundColor Green
Write-Host "File: `$PSScriptRoot\config\appsettings.json" -ForegroundColor DarkGray
"@

$testWebhookScript = @"
Set-ExecutionPolicy -Scope Process Bypass -Force

. "`$PSScriptRoot\modules\Common.ps1"
. "`$PSScriptRoot\publishers\N8nWebhook.ps1"

Set-Utf8Console
Initialize-SocialHub -RootDir `$PSScriptRoot

`$settings = Read-AppSettings -RootDir `$PSScriptRoot

`$post = [PSCustomObject]@{
    createdAt = (Get-Date).ToString("s")
    model     = "manual-test"
    prompt    = "test webhook"
    content   = "Test tecnico da SuiteV17 SocialHub."
}

try {
    `$res = Invoke-N8nPublish -RootDir `$PSScriptRoot -PostObject `$post -Settings `$settings -Platforms @("instagram","facebook") -TestMode
    Write-Host "Test webhook riuscito." -ForegroundColor Green
    Write-Host "Risposta salvata in: `$(`$res.LatestResponse)" -ForegroundColor DarkGray
}
catch {
    Write-Host "Test webhook fallito: `$(`$_.Exception.Message)" -ForegroundColor Red
    throw
}
"@

$readme = @"
SUITEV17 SOCIALHUB

Comandi principali:

1) Configura il webhook n8n
   .\Configure-SocialHub.ps1

2) Genera un post e chiedi conferma
   .\Run-SocialHub.ps1

3) Genera con prompt personalizzato
   .\Run-SocialHub.ps1 -Prompt "Scrivi un post social breve e potente su Gene1799artcorporatione."

4) Genera e pubblica subito
   .\Run-SocialHub.ps1 -AutoPublish

5) Genera con immagine
   .\Run-SocialHub.ps1 -ImagePath "C:\Percorso\immagine.jpg"

6) Test del webhook
   .\Test-N8nWebhook.ps1

Note:
- La chiave Groq viene letta da GROQ_API_KEY oppure da archivio locale cifrato.
- Il webhook n8n viene salvato in archivio locale cifrato.
- I payload non pubblicati restano in queue\pending
- Quelli pubblicati finiscono in queue\published
"@

W -Path "$root\config\appsettings.json" -Content $appSettings
W -Path "$root\modules\Common.ps1" -Content $common
W -Path "$root\modules\GroqClient.ps1" -Content $groqClient
W -Path "$root\publishers\N8nWebhook.ps1" -Content $n8nPublisher
W -Path "$root\Start-SocialHub.ps1" -Content $startScript
W -Path "$root\Run-SocialHub.ps1" -Content $runScript
W -Path "$root\Configure-SocialHub.ps1" -Content $configureScript
W -Path "$root\Test-N8nWebhook.ps1" -Content $testWebhookScript
W -Path "$root\README.txt" -Content $readme

Write-Host ""
Write-Host "SOCIALHUB V1 CREATO CON SUCCESSO" -ForegroundColor Green
Write-Host "Cartella: $root" -ForegroundColor Green
Write-Host ""
Write-Host "Comandi adesso:" -ForegroundColor Yellow
Write-Host "cd C:\SuiteV17\SocialHubV1"
Write-Host ".\Configure-SocialHub.ps1"
Write-Host ".\Run-SocialHub.ps1"
