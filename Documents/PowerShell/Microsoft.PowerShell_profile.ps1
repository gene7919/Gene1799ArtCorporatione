# PowerShell Profile personalizzato

# Alias utili
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name grep -Value Select-String
Set-Alias -Name which -Value Get-Command

# Funzioni utili
function Get-PublicIP { 
    (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content 
}

function Open-Here { 
    explorer . 
}

function Edit-Profile { 
    notepad C:\Users\gene1\Desktop\gene1799\Gene1799ArtCorporatione\Documents\PowerShell\Microsoft.PowerShell_profile.ps1 
}

# Messaggio di benvenuto
Write-Host "PowerShell Profile caricato!" -ForegroundColor Green
Write-Host "Usa 'Get-Help about_profiles' per saperne di più sui profili." -ForegroundColor Yellow

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
