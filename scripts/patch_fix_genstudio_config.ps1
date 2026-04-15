$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " GENSTUDIO // FIX CONFIG PATCH " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$ConfigPath = "C:\SuiteV17\GenStudio\config.json"

if (!(Test-Path $ConfigPath)) {
    throw "config.json non trovato: $ConfigPath"
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

# -------- text --------
if (-not ($config.PSObject.Properties.Name -contains "text")) {
    $config | Add-Member -MemberType NoteProperty -Name text -Value ([pscustomobject]@{
        engine = "ollama-aihub"
        enabled = $true
        script = "C:\SuiteV17\GenStudio\skills\text_generate.ps1"
        defaultModel = "qwen3:4b"
    })
}
else {
    $config.text.engine = "ollama-aihub"
    $config.text.enabled = $true
    $config.text.script = "C:\SuiteV17\GenStudio\skills\text_generate.ps1"
    $config.text.defaultModel = "qwen3:4b"
}

# -------- audio --------
if (-not ($config.PSObject.Properties.Name -contains "audio")) {
    $config | Add-Member -MemberType NoteProperty -Name audio -Value ([pscustomobject]@{
        engine = "musicgen"
        enabled = $false
        script = "C:\SuiteV17\GenStudio\skills\audio_generate.ps1"
        orchestrator = "C:\SuiteV17\GenStudio\skills\music_orchestrator.ps1"
        defaultDuration = 8
    })
}
else {
    $config.audio.engine = "musicgen"
    $config.audio.enabled = $false
    $config.audio.script = "C:\SuiteV17\GenStudio\skills\audio_generate.ps1"

    if (-not ($config.audio.PSObject.Properties.Name -contains "orchestrator")) {
        $config.audio | Add-Member -MemberType NoteProperty -Name orchestrator -Value "C:\SuiteV17\GenStudio\skills\music_orchestrator.ps1"
    }
    else {
        $config.audio.orchestrator = "C:\SuiteV17\GenStudio\skills\music_orchestrator.ps1"
    }

    if (-not ($config.audio.PSObject.Properties.Name -contains "defaultDuration")) {
        $config.audio | Add-Member -MemberType NoteProperty -Name defaultDuration -Value 8
    }
    else {
        $config.audio.defaultDuration = 8
    }
}

# -------- video --------
if (-not ($config.PSObject.Properties.Name -contains "video")) {
    $config | Add-Member -MemberType NoteProperty -Name video -Value ([pscustomobject]@{
        engine = "ltx-video"
        enabled = $false
        script = "C:\SuiteV17\GenStudio\skills\video_generate.ps1"
        coordinator = "C:\SuiteV17\GenStudio\skills\video_coordinator.ps1"
        defaultDuration = 4
        defaultFps = 24
        defaultResolution = "768x432"
    })
}
else {
    $config.video.engine = "ltx-video"
    $config.video.enabled = $false
    $config.video.script = "C:\SuiteV17\GenStudio\skills\video_generate.ps1"

    if (-not ($config.video.PSObject.Properties.Name -contains "coordinator")) {
        $config.video | Add-Member -MemberType NoteProperty -Name coordinator -Value "C:\SuiteV17\GenStudio\skills\video_coordinator.ps1"
    }
    else {
        $config.video.coordinator = "C:\SuiteV17\GenStudio\skills\video_coordinator.ps1"
    }

    if (-not ($config.video.PSObject.Properties.Name -contains "defaultDuration")) {
        $config.video | Add-Member -MemberType NoteProperty -Name defaultDuration -Value 4
    }
    else {
        $config.video.defaultDuration = 4
    }

    if (-not ($config.video.PSObject.Properties.Name -contains "defaultFps")) {
        $config.video | Add-Member -MemberType NoteProperty -Name defaultFps -Value 24
    }
    else {
        $config.video.defaultFps = 24
    }

    if (-not ($config.video.PSObject.Properties.Name -contains "defaultResolution")) {
        $config.video | Add-Member -MemberType NoteProperty -Name defaultResolution -Value "768x432"
    }
    else {
        $config.video.defaultResolution = "768x432"
    }
}

$config | ConvertTo-Json -Depth 20 | Set-Content $ConfigPath -Encoding UTF8

Write-Host "config.json corretto con successo." -ForegroundColor Green
Write-Host $ConfigPath -ForegroundColor Yellow