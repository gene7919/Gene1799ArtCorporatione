$ErrorActionPreference = "Stop"

$candidates = @(
    "C:\Cloudflared\bin\cloudflared.exe",
    "C:\Program Files (x86)\cloudflared\cloudflared.exe",
    "C:\Program Files\cloudflared\cloudflared.exe",
    "$env:USERPROFILE\.cloudflared\cloudflared.exe"
)

$cmd = Get-Command cloudflared -ErrorAction SilentlyContinue
if ($cmd) {
    $exe = $cmd.Source
}
else {
    $exe = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $exe) {
    Write-Error "cloudflared.exe non trovato."
    exit 1
}

Write-Host "Uso cloudflared da: $exe"
& $exe tunnel run gene1799
exit $LASTEXITCODE
