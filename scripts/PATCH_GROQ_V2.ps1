$ErrorActionPreference = "Stop"

$root = "C:\SuiteV17"
$testPath = Join-Path $root "Test-Groq.ps1"
$resetPath = Join-Path $root "Reset-GroqKey.ps1"
$secretDir = Join-Path $env:USERPROFILE ".suitev17"
$secretPath = Join-Path $secretDir "groq_api_key.secure"

New-Item -ItemType Directory -Path $root -Force | Out-Null
New-Item -ItemType Directory -Path $secretDir -Force | Out-Null

$resetContent = @'
$ErrorActionPreference = "Stop"

$secretPath = Join-Path $env:USERPROFILE ".suitev17\groq_api_key.secure"

if (Test-Path $secretPath) {
    Remove-Item $secretPath -Force
    Write-Host "Chiave locale eliminata: $secretPath" -ForegroundColor Yellow
} else {
    Write-Host "Nessuna chiave locale trovata." -ForegroundColor DarkYellow
}

if (Test-Path Env:GROQ_API_KEY) {
    Remove-Item Env:GROQ_API_KEY -ErrorAction SilentlyContinue
    Write-Host "Variabile di sessione GROQ_API_KEY rimossa." -ForegroundColor Yellow
} else {
    Write-Host "Nessuna GROQ_API_KEY nella sessione corrente." -ForegroundColor DarkYellow
}

Write-Host "Reset completato." -ForegroundColor Green
'@

Set-Content -Path $resetPath -Value $resetContent -Encoding UTF8

$testContent = @'
[CmdletBinding()]
param(
    [string]$Model = "llama-3.3-70b-versatile"
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
        [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        if ($bstr -ne [IntPtr]::Zero) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}

function Save-GroqApiKey {
    param([Parameter(Mandatory=$true)][string]$ApiKey)

    $dir = Join-Path $env:USERPROFILE ".suitev17"
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $path = Join-Path $dir "groq_api_key.secure"
    $secure = ConvertTo-SecureString -String $ApiKey -AsPlainText -Force
    $encrypted = $secure | ConvertFrom-SecureString
    Set-Content -Path $path -Value $encrypted -Encoding UTF8
}

function Read-GroqApiKey {
    $secureInput = Read-Host "Incolla la tua NUOVA chiave Groq" -AsSecureString
    $apiKey = (ConvertTo-PlainText -SecureString $secureInput).Trim()

    if (-not $apiKey.StartsWith("gsk_")) {
        throw "La chiave non sembra valida: deve iniziare con gsk_."
    }

    return $apiKey
}

function Read-ErrorBody {
    param($ErrorRecord)

    try {
        $resp = $ErrorRecord.Exception.Response
        if ($resp -and $resp.GetResponseStream) {
            $stream = $resp.GetResponseStream()
            if ($stream) {
                $reader = New-Object System.IO.StreamReader($stream)
                return $reader.ReadToEnd()
            }
        }
    }
    catch {}

    return $ErrorRecord.Exception.Message
}

$apiKey = Read-GroqApiKey

$headers = @{
    Authorization = "Bearer $apiKey"
    "Content-Type" = "application/json"
}

$body = @{
    model = $Model
    messages = @(
        @{
            role = "user"
            content = "Scrivi una breve e allegra frase di prova."
        }
    )
} | ConvertTo-Json -Depth 10

Write-Host "Invio richiesta a Groq..." -ForegroundColor Cyan
Write-Host ("Endpoint: https://api.groq.com/openai/v1/chat/completions") -ForegroundColor DarkGray
Write-Host ("Modello:  {0}" -f $Model) -ForegroundColor DarkGray
Write-Host ("Header Authorization: Bearer {0}..." -f $apiKey.Substring(0, [Math]::Min(8, $apiKey.Length))) -ForegroundColor DarkGray

try {
    $response = Invoke-RestMethod `
        -Uri "https://api.groq.com/openai/v1/chat/completions" `
        -Method Post `
        -Headers $headers `
        -Body $body

    $text = $response.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($text)) {
        throw "Risposta vuota."
    }

    Save-GroqApiKey -ApiKey $apiKey

    Write-Host ""
    Write-Host "TEST OK" -ForegroundColor Green
    Write-Host $text -ForegroundColor Green
}
catch {
    $msg = Read-ErrorBody -ErrorRecord $_
    Write-Host ""
    Write-Host "TEST FALLITO" -ForegroundColor Red
    Write-Host $msg -ForegroundColor Yellow
    throw
}
'@

Set-Content -Path $testPath -Value $testContent -Encoding UTF8

Write-Host ""
Write-Host "PATCH V2 COMPLETATA" -ForegroundColor Green
Write-Host "Creati:" -ForegroundColor Green
Write-Host " - $resetPath"
Write-Host " - $testPath"
Write-Host ""
Write-Host "Esegui ORA:" -ForegroundColor Yellow
Write-Host "1) .\Reset-GroqKey.ps1"
Write-Host "2) .\Test-Groq.ps1"