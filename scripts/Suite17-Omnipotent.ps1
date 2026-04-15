Write-Host ""
Write-Host "SUITE17 OMNIPOTENT MODE" -ForegroundColor Cyan
Write-Host ""

# cartelle da analizzare
$paths = @(
"C:\SuiteV17",
"C:\Users",
"D:\"
)

# controlla spazio disco
Write-Host "Controllo dischi..."

Get-PSDrive C
Get-PSDrive D

# conta file
Write-Host "Indicizzazione file..."

foreach ($p in $paths) {
    Write-Host "Scanning $p"
    $count = (Get-ChildItem $p -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
    Write-Host "$p -> $count file"
}

# test LLM
Write-Host ""
Write-Host "Test AI..."

ollama run llama3.1 "rispondi OK"

# test embedding
Write-Host ""
Write-Host "Test embedding..."

ollama run nomic-embed-text "Suite17 test"

# stato agenti
Write-Host ""
Write-Host "Stato AI Agents"

pm2 list

Write-Host ""
Write-Host "SUITE17 OMNIPOTENT READY" -ForegroundColor Green