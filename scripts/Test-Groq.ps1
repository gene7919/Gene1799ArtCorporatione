param(
    [string]$Model = "llama-3.3-70b-versatile"
)

Set-ExecutionPolicy -Scope Process Bypass -Force
& "$PSScriptRoot\MainApp.ps1" -Prompt "Scrivi una breve e allegra frase di prova." -ModelFallback @($Model)
