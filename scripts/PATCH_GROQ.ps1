$ErrorActionPreference = "Stop"

$root = "C:\SuiteV17"
$mainPath = Join-Path $root "MainApp.ps1"
$launcherPath = Join-Path $root "Run-MainApp.ps1"
$backupDir = Join-Path $root "backup"

New-Item -ItemType Directory -Path $root -Force | Out-Null
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

if (Test-Path $mainPath) {
    $backupName = "MainApp_{0}.ps1.bak" -f (Get-Date -Format "yyyyMMdd_HHmmss")
    Copy-Item $mainPath (Join-Path $backupDir $backupName) -Force
}

$mainContent = @'
[CmdletBinding()]
param(
    [string]$Prompt = "Scrivi una breve e allegra frase per test.",
    [string[]]$ModelFallback = @(
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant"
    )
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-PlainText {
    param(
        [Parameter(Mandatory=$true)]
        [Security.SecureString]$SecureString
    )

    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Get-SecretStorePath {
    $dir = Join-Path $env:USERPROFILE ".suitev17"
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return Join-Path $dir "groq_api_key.secure"
}

function Save-GroqApiKey {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApiKey
    )

    $secure = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
    $encrypted = $secure | ConvertFrom-SecureString
    $path = Get-SecretStorePath
    Set-Content -Path $path -Value $encrypted -Encoding UTF8
}

function Get-GroqApiKey {
    if ($env:GROQ_API_KEY -and $env:GROQ_API_KEY.Trim().StartsWith("gsk_")) {
        return $env:GROQ_API_KEY.Trim()
    }

    $secretPath = Get-SecretStorePath
    if (Test-Path $secretPath) {
        try {
            $encrypted = Get-Content -Path $secretPath -Raw
            if ($encrypted) {
                $secure = $encrypted | ConvertTo-SecureString
                $plain = ConvertTo-PlainText -SecureString $secure
                if ($plain -and $plain.Trim().StartsWith("gsk_")) {
                    return $plain.Trim()
                }
            }
        }
        catch {
            Write-Warning "Chiave locale non leggibile. Verrà richiesta di nuovo."
        }
    }

    Write-Host "Chiave API di Groq non trovata." -ForegroundColor Yellow
    $secureInput = Read-Host "Incolla la tua NUOVA chiave API di Groq" -AsSecureString
    $apiKey = ConvertTo-PlainText -SecureString $secureInput
    $apiKey = $apiKey.Trim()

    if (-not $apiKey.StartsWith("gsk_")) {
        throw "La chiave non sembra valida: deve iniziare con gsk_."
    }

    Save-GroqApiKey -ApiKey $apiKey
    return $apiKey
}

function Get-ErrorDetails {
    param(
        [Parameter(Mandatory=$true)]
        $ErrorRecord
    )

    $statusCode = $null
    $bodyText = $null

    try {
        if ($ErrorRecord.Exception.Response) {
            $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode
        }
    }
    catch {}

    try {
        $resp = $ErrorRecord.Exception.Response
        if ($resp -and $resp.GetResponseStream) {
            $stream = $resp.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                $bodyText = $reader.ReadToEnd()
            }
        }
    }
    catch {}

    if (-not $bodyText) {
        $bodyText = $ErrorRecord.Exception.Message
    }

    return [PSCustomObject]@{
        StatusCode = $statusCode
        Body       = $bodyText
    }
}

function Invoke-GroqRaw {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ApiKey,

        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$true)]
        [string]$Model
    )

    $headers = @{
        Authorization = "Bearer $ApiKey"
        "Content-Type" = "application/json"
    }

    $bodyObject = @{
        model = $Model
        messages = @(
            @{
                role    = "user"
                content = $Prompt
            }
        )
        temperature = 0.7
    }

    $json = $bodyObject | ConvertTo-Json -Depth 10

    return Invoke-RestMethod `
        -Uri "https://api.groq.com/openai/v1/chat/completions" `
        -Method Post `
        -Headers $headers `
        -Body $json
}

function Invoke-Groq {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        [Parameter(Mandatory=$true)]
        [string]$ApiKey,

        [string[]]$ModelFallback = @(
            "llama-3.3-70b-versatile",
            "llama-3.1-8b-instant"
        )
    )

    $lastError = $null

    foreach ($model in $ModelFallback) {
        try {
            Write-Host "Tentativo Groq con modello: $model" -ForegroundColor Cyan
            $response = Invoke-GroqRaw -ApiKey $ApiKey -Prompt $Prompt -Model $model
            $content = $response.choices[0].message.content

            if ([string]::IsNullOrWhiteSpace($content)) {
                throw "Risposta vuota da Groq."
            }

            return [PSCustomObject]@{
                ModelUsed = $model
                Content   = $content
            }
        }
        catch {
            $details = Get-ErrorDetails -ErrorRecord $_
            $lastError = $details

            if ($details.StatusCode -eq 401) {
                throw "ERRORE GROQ 401 Unauthorized. La chiave API non è valida, è stata revocata, oppure non viene inviata correttamente nell'header Authorization. Dettagli: $($details.Body)"
            }

            if ($details.StatusCode -notin 400,404) {
                throw "ERRORE GROQ HTTP $($details.StatusCode). Dettagli: $($details.Body)"
            }

            Write-Warning "Modello $model non accettato o non disponibile. Provo il successivo."
        }
    }

    throw "Nessun modello ha funzionato. Ultimo errore: HTTP $($lastError.StatusCode) - $($lastError.Body)"
}

try {
    $apiKey = Get-GroqApiKey
    Write-Host "Sto generando un post di prova con Groq..." -ForegroundColor Green

    $result = Invoke-Groq -Prompt $Prompt -ApiKey $apiKey -ModelFallback $ModelFallback

    Write-Host ""
    Write-Host "=== RISPOSTA GROQ ===" -ForegroundColor Green
    Write-Host $result.Content
    Write-Host ""
    Write-Host "Modello usato: $($result.ModelUsed)" -ForegroundColor DarkGray
}
catch {
    Write-Error $_
    exit 1
}
'@

Set-Content -Path $mainPath -Value $mainContent -Encoding UTF8

$launcherContent = @'
Set-ExecutionPolicy -Scope Process Bypass -Force
& "$PSScriptRoot\MainApp.ps1"
'@

Set-Content -Path $launcherPath -Value $launcherContent -Encoding UTF8

Write-Host ""
Write-Host "PATCH COMPLETATA" -ForegroundColor Green
Write-Host "Backup salvato in: $backupDir" -ForegroundColor Green
Write-Host "Creati/aggiornati:" -ForegroundColor Green
Write-Host " - $mainPath"
Write-Host " - $launcherPath"
Write-Host ""
Write-Host "Esegui ora questi comandi:" -ForegroundColor Yellow
Write-Host "cd C:\SuiteV17"
Write-Host "powershell -ExecutionPolicy Bypass -File .\PATCH_GROQ.ps1"
Write-Host ".\Run-MainApp.ps1"