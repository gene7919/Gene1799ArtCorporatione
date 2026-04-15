[CmdletBinding()]
param(
    [string]$Prompt = "Scrivi una breve e allegra frase per test.",
    [string[]]$ModelFallback = @(
        "llama-3.3-70b-versatile",
        "llama-3.1-8b-instant"
    ),
    [int]$MaxRetries = 3,
    [string]$OutputFile = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script:RootDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$Script:LogsDir = Join-Path $Script:RootDir "logs"
$Script:OutputDir = Join-Path $Script:RootDir "output"

New-Item -ItemType Directory -Path $Script:LogsDir -Force | Out-Null
New-Item -ItemType Directory -Path $Script:OutputDir -Force | Out-Null

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path $Script:OutputDir "latest_post.txt"
}

$Script:LogFile = Join-Path $Script:LogsDir ("groq_{0}.log" -f (Get-Date -Format "yyyyMMdd"))

function Write-Log {
    param(
        [Parameter(Mandatory=$true)][string]$Message,
        [ValidateSet("INFO","WARN","ERROR","OK")][string]$Level = "INFO"
    )

    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $Level, $Message
    Add-Content -Path $Script:LogFile -Value $line -Encoding UTF8

    switch ($Level) {
        "INFO"  { Write-Host $line -ForegroundColor Cyan }
        "WARN"  { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "OK"    { Write-Host $line -ForegroundColor Green }
    }
}

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
        [Parameter(Mandatory=$true)][string]$ApiKey
    )

    $secure = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
    $encrypted = $secure | ConvertFrom-SecureString
    $path = Get-SecretStorePath
    Set-Content -Path $path -Value $encrypted -Encoding UTF8
    Write-Log "Chiave Groq salvata in archivio cifrato locale." "OK"
}

function Get-GroqApiKey {
    if ($env:GROQ_API_KEY -and $env:GROQ_API_KEY.Trim().StartsWith("gsk_")) {
        Write-Log "Chiave Groq letta da variabile ambiente." "INFO"
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
                    Write-Log "Chiave Groq letta da archivio locale cifrato." "INFO"
                    return $plain.Trim()
                }
            }
        }
        catch {
            Write-Log "Archivio chiave locale non leggibile. VerrÃ  richiesta una nuova chiave." "WARN"
        }
    }

    Write-Host "Chiave API di Groq non trovata." -ForegroundColor Yellow
    $secureInput = Read-Host "Incolla la tua chiave API di Groq" -AsSecureString
    $apiKey = ConvertTo-PlainText -SecureString $secureInput
    $apiKey = $apiKey.Trim()

    if (-not $apiKey.StartsWith("gsk_")) {
        throw "La chiave non sembra valida: deve iniziare con gsk_."
    }

    Save-GroqApiKey -ApiKey $apiKey
    return $apiKey
}

function Get-HttpErrorInfo {
    param(
        [Parameter(Mandatory=$true)]$ErrorRecord
    )

    $statusCode = $null
    $body = $null
    $message = $ErrorRecord.Exception.Message

    try {
        if ($ErrorRecord.Exception.Response -and $ErrorRecord.Exception.Response.StatusCode) {
            $statusCode = [int]$ErrorRecord.Exception.Response.StatusCode
        }
    }
    catch {}

    try {
        if ($ErrorRecord.ErrorDetails -and $ErrorRecord.ErrorDetails.Message) {
            $body = $ErrorRecord.ErrorDetails.Message
        }
    }
    catch {}

    if (-not $body) {
        $body = $message
    }

    [PSCustomObject]@{
        StatusCode = $statusCode
        Body       = $body
        Message    = $message
    }
}

function Invoke-GroqRaw {
    param(
        [Parameter(Mandatory=$true)][string]$ApiKey,
        [Parameter(Mandatory=$true)][string]$Prompt,
        [Parameter(Mandatory=$true)][string]$Model
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

function Invoke-GroqWithRetry {
    param(
        [Parameter(Mandatory=$true)][string]$ApiKey,
        [Parameter(Mandatory=$true)][string]$Prompt,
        [Parameter(Mandatory=$true)][string]$Model,
        [int]$Retries = 3
    )

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            Write-Log ("Tentativo {0}/{1} con modello: {2}" -f $attempt, $Retries, $Model) "INFO"
            $response = Invoke-GroqRaw -ApiKey $ApiKey -Prompt $Prompt -Model $Model
            return $response
        }
        catch {
            $err = Get-HttpErrorInfo -ErrorRecord $_
            $transient = $false

            if ($err.StatusCode -in 408, 429, 500, 502, 503, 504) {
                $transient = $true
            }

            if ($err.StatusCode -eq 401) {
                throw "ERRORE GROQ 401 Unauthorized. Chiave non valida, revocata o non inviata correttamente."
            }

            if ($attempt -lt $Retries -and $transient) {
                $sleepSeconds = [Math]::Min(10, [Math]::Pow(2, $attempt))
                Write-Log ("Errore temporaneo HTTP {0}. Attendo {1}s e riprovo." -f $err.StatusCode, $sleepSeconds) "WARN"
                Start-Sleep -Seconds $sleepSeconds
                continue
            }

            throw "ERRORE GROQ HTTP $($err.StatusCode). Dettagli: $($err.Body)"
        }
    }

    throw "Chiamata Groq fallita dopo $Retries tentativi."
}

function Invoke-Groq {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [Parameter(Mandatory=$true)][string]$ApiKey,
        [Parameter(Mandatory=$true)][string[]]$ModelFallback,
        [int]$Retries = 3
    )

    $lastError = $null

    foreach ($model in $ModelFallback) {
        try {
            $response = Invoke-GroqWithRetry -ApiKey $ApiKey -Prompt $Prompt -Model $model -Retries $Retries
            $content = $response.choices[0].message.content

            if ([string]::IsNullOrWhiteSpace($content)) {
                throw "Risposta vuota dal modello $model."
            }

            return [PSCustomObject]@{
                ModelUsed = $model
                Content   = $content.Trim()
            }
        }
        catch {
            $lastError = $_.Exception.Message
            Write-Log ("Modello fallito: {0} | {1}" -f $model, $lastError) "WARN"
        }
    }

    throw "Nessun modello ha funzionato. Ultimo errore: $lastError"
}

try {
    Write-Log "Avvio MainApp.ps1" "INFO"
    $apiKey = Get-GroqApiKey

    $result = Invoke-Groq -Prompt $Prompt -ApiKey $apiKey -ModelFallback $ModelFallback -Retries $MaxRetries

    Set-Content -Path $OutputFile -Value $result.Content -Encoding UTF8

    Write-Host ""
    Write-Host "=== RISPOSTA GROQ ===" -ForegroundColor Green
    Write-Host $result.Content
    Write-Host ""
    Write-Host "Modello usato: $($result.ModelUsed)" -ForegroundColor DarkGray
    Write-Host "Output salvato in: $OutputFile" -ForegroundColor DarkGray
    Write-Host "Log file: $Script:LogFile" -ForegroundColor DarkGray

    Write-Log ("Completato con successo. Modello usato: {0}" -f $result.ModelUsed) "OK"
}
catch {
    Write-Log $_.Exception.Message "ERROR"
    throw
}
