$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " GENSTUDIO // SKILLS ORCHESTRATE PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$Root = "C:\SuiteV17"
$GenStudio = Join-Path $Root "GenStudio"
$Skills = Join-Path $GenStudio "skills"
$Output = Join-Path $GenStudio "output"
$TextOut = Join-Path $Output "text"
$AudioOut = Join-Path $Output "audio"
$VideoOut = Join-Path $Output "video"
$JobsOut = Join-Path $Output "jobs"
$LogsOut = Join-Path $GenStudio "logs"
$ConfigPath = Join-Path $GenStudio "config.json"

foreach ($dir in @($GenStudio,$Skills,$Output,$TextOut,$AudioOut,$VideoOut,$JobsOut,$LogsOut)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

$ts = Get-Date -Format "yyyyMMdd_HHmmss"

$filesToBackup = @(
    (Join-Path $Skills "audio_generate.ps1"),
    (Join-Path $Skills "video_generate.ps1"),
    (Join-Path $Skills "text_generate.ps1"),
    (Join-Path $Skills "music_orchestrator.ps1"),
    (Join-Path $Skills "video_coordinator.ps1")
)

foreach ($f in $filesToBackup) {
    if (Test-Path $f) {
        Copy-Item $f "$f.bak_$ts" -Force
    }
}

$textGenerate = @'
param(
    [string]$Prompt,
    [string]$Model = "qwen3:4b",
    [string]$Mode = "creative",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function New-TimeStamp {
    Get-Date -Format "yyyyMMdd_HHmmss"
}

function Ensure-Parent([string]$Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

if (-not $Prompt) {
    throw "Prompt mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\text\text_" + (New-TimeStamp) + ".json"
}

Ensure-Parent $OutputFile

$payload = @{
    prompt = $Prompt
    model  = $Model
    mode   = $Mode
    createdAt = (Get-Date).ToString("s")
    source = "GenStudio text_generate.ps1"
} | ConvertTo-Json -Depth 10

try {
    $resp = Invoke-RestMethod `
        -Uri "http://127.0.0.1:3020/api/generate/social" `
        -Method Post `
        -ContentType "application/json" `
        -Body $payload

    $result = @{
        ok = $true
        prompt = $Prompt
        model = $Model
        mode = $Mode
        output = $resp
        savedAt = (Get-Date).ToString("s")
    }

    $result | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
    Write-Host "Text generated -> $OutputFile" -ForegroundColor Green
}
catch {
    $fallback = @{
        ok = $false
        prompt = $Prompt
        model = $Model
        mode = $Mode
        error = $_.Exception.Message
        savedAt = (Get-Date).ToString("s")
    }

    $fallback | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
    Write-Host "Errore text_generate: $($_.Exception.Message)" -ForegroundColor Red
}
'@

$musicOrchestrator = @'
param(
    [string]$Prompt,
    [int]$Duration = 8,
    [string]$Style = "cinematic",
    [string]$Mood = "dark",
    [string]$Model = "musicgen",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function New-TimeStamp {
    Get-Date -Format "yyyyMMdd_HHmmss"
}

function Ensure-Parent([string]$Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

if (-not $Prompt) {
    throw "Prompt musicale mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\audio\music_job_" + (New-TimeStamp) + ".json"
}

Ensure-Parent $OutputFile

$job = @{
    type = "music_orchestrator"
    prompt = $Prompt
    duration = $Duration
    style = $Style
    mood = $Mood
    model = $Model
    engine = "MusicGen/AudioCraft ready"
    createdAt = (Get-Date).ToString("s")
    recommendedPrompt = "$Style, $Mood, $Prompt, high quality, coherent arrangement, no vocals unless requested"
    status = "prepared"
    nextStep = "Collegare skill audio reale a MusicGen"
}

$job | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
Write-Host "Music orchestration prepared -> $OutputFile" -ForegroundColor Green
'@

$audioGenerate = @'
param(
    [string]$Prompt,
    [int]$Duration = 8,
    [string]$Style = "cinematic",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function New-TimeStamp {
    Get-Date -Format "yyyyMMdd_HHmmss"
}

function Ensure-Parent([string]$Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

if (-not $Prompt) {
    throw "Prompt audio mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\audio\audio_" + (New-TimeStamp) + ".json"
}

Ensure-Parent $OutputFile

$orchestrator = "C:\SuiteV17\GenStudio\skills\music_orchestrator.ps1"
if (!(Test-Path $orchestrator)) {
    throw "music_orchestrator.ps1 non trovato."
}

$prepFile = [System.IO.Path]::ChangeExtension($OutputFile, ".prep.json")

powershell -NoProfile -ExecutionPolicy Bypass `
    -File $orchestrator `
    -Prompt $Prompt `
    -Duration $Duration `
    -Style $Style `
    -OutputFile $prepFile | Out-Null

$result = @{
    ok = $true
    prompt = $Prompt
    duration = $Duration
    style = $Style
    orchestratorFile = $prepFile
    outputTarget = $OutputFile
    engine = "Audio skill placeholder"
    status = "prepared"
    note = "Qui collegheremo MusicGen / AudioCraft reale."
    savedAt = (Get-Date).ToString("s")
}

$result | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
Write-Host "Audio job prepared -> $OutputFile" -ForegroundColor Green
'@

$videoCoordinator = @'
param(
    [string]$Prompt,
    [int]$Duration = 4,
    [int]$Fps = 24,
    [string]$Resolution = "768x432",
    [string]$Style = "cinematic",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function New-TimeStamp {
    Get-Date -Format "yyyyMMdd_HHmmss"
}

function Ensure-Parent([string]$Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

if (-not $Prompt) {
    throw "Prompt video mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\video\video_job_" + (New-TimeStamp) + ".json"
}

Ensure-Parent $OutputFile

$job = @{
    type = "video_coordinator"
    prompt = $Prompt
    duration = $Duration
    fps = $Fps
    resolution = $Resolution
    style = $Style
    engine = "LTX-Video ready"
    createdAt = (Get-Date).ToString("s")
    recommendedPrompt = "$Style, coherent motion, stable camera, clean composition, $Prompt"
    status = "prepared"
    nextStep = "Collegare skill video reale a LTX-Video"
}

$job | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
Write-Host "Video coordination prepared -> $OutputFile" -ForegroundColor Green
'@

$videoGenerate = @'
param(
    [string]$Prompt,
    [int]$Duration = 4,
    [int]$Fps = 24,
    [string]$Resolution = "768x432",
    [string]$OutputFile = ""
)

$ErrorActionPreference = "Stop"

function New-TimeStamp {
    Get-Date -Format "yyyyMMdd_HHmmss"
}

function Ensure-Parent([string]$Path) {
    $parent = Split-Path -Parent $Path
    if ($parent -and !(Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
}

if (-not $Prompt) {
    throw "Prompt video mancante."
}

if (-not $OutputFile) {
    $OutputFile = "C:\SuiteV17\GenStudio\output\video\video_" + (New-TimeStamp) + ".json"
}

Ensure-Parent $OutputFile

$coordinator = "C:\SuiteV17\GenStudio\skills\video_coordinator.ps1"
if (!(Test-Path $coordinator)) {
    throw "video_coordinator.ps1 non trovato."
}

$prepFile = [System.IO.Path]::ChangeExtension($OutputFile, ".prep.json")

powershell -NoProfile -ExecutionPolicy Bypass `
    -File $coordinator `
    -Prompt $Prompt `
    -Duration $Duration `
    -Fps $Fps `
    -Resolution $Resolution `
    -OutputFile $prepFile | Out-Null

$result = @{
    ok = $true
    prompt = $Prompt
    duration = $Duration
    fps = $Fps
    resolution = $Resolution
    coordinatorFile = $prepFile
    outputTarget = $OutputFile
    engine = "Video skill placeholder"
    status = "prepared"
    note = "Qui collegheremo LTX-Video reale."
    savedAt = (Get-Date).ToString("s")
}

$result | ConvertTo-Json -Depth 20 | Set-Content $OutputFile -Encoding UTF8
Write-Host "Video job prepared -> $OutputFile" -ForegroundColor Green
'@

Set-Content -Path (Join-Path $Skills "text_generate.ps1") -Value $textGenerate -Encoding UTF8
Set-Content -Path (Join-Path $Skills "music_orchestrator.ps1") -Value $musicOrchestrator -Encoding UTF8
Set-Content -Path (Join-Path $Skills "audio_generate.ps1") -Value $audioGenerate -Encoding UTF8
Set-Content -Path (Join-Path $Skills "video_coordinator.ps1") -Value $videoCoordinator -Encoding UTF8
Set-Content -Path (Join-Path $Skills "video_generate.ps1") -Value $videoGenerate -Encoding UTF8

if (Test-Path $ConfigPath) {
    $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json

    if (-not $cfg.PSObject.Properties.Name.Contains("text")) {
        $cfg | Add-Member -MemberType NoteProperty -Name text -Value ([pscustomobject]@{
            engine = "ollama-aihub"
            enabled = $true
            script = "C:\SuiteV17\GenStudio\skills\text_generate.ps1"
            defaultModel = "qwen3:4b"
        })
    } else {
        $cfg.text.engine = "ollama-aihub"
        $cfg.text.enabled = $true
        $cfg.text.script = "C:\SuiteV17\GenStudio\skills\text_generate.ps1"
        $cfg.text.defaultModel = "qwen3:4b"
    }

    $cfg.audio.script = "C:\SuiteV17\GenStudio\skills\audio_generate.ps1"
    $cfg.audio.orchestrator = "C:\SuiteV17\GenStudio\skills\music_orchestrator.ps1"

    $cfg.video.script = "C:\SuiteV17\GenStudio\skills\video_generate.ps1"
    $cfg.video.coordinator = "C:\SuiteV17\GenStudio\skills\video_coordinator.ps1"

    $cfg | ConvertTo-Json -Depth 20 | Set-Content $ConfigPath -Encoding UTF8
    Write-Host "config.json aggiornato." -ForegroundColor Green
}
else {
    Write-Host "config.json non trovato, skills create comunque." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host " SKILLS GENSTUDIO AGGIORNATE " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Create/aggiornate:"
Write-Host " - C:\SuiteV17\GenStudio\skills\text_generate.ps1"
Write-Host " - C:\SuiteV17\GenStudio\skills\music_orchestrator.ps1"
Write-Host " - C:\SuiteV17\GenStudio\skills\audio_generate.ps1"
Write-Host " - C:\SuiteV17\GenStudio\skills\video_coordinator.ps1"
Write-Host " - C:\SuiteV17\GenStudio\skills\video_generate.ps1"