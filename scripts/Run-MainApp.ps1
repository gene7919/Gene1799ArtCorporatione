param(
    [string]$Prompt = "Scrivi una breve e allegra frase per test."
)

Set-ExecutionPolicy -Scope Process Bypass -Force
& "$PSScriptRoot\MainApp.ps1" -Prompt $Prompt
