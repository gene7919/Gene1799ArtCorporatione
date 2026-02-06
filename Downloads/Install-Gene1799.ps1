<#
.SYNOPSIS
Installa il pacchetto Gene1799 Core per firma digitale NFT

.DESCRIPTION
Script per l'installazione automatizzata del pacchetto Gene1799 Core 
su sistemi Windows con Python 3.8+

.EXAMPLE
.\Install-Gene1799.ps1
#>

param(
    [switch]$Verbose = $false,
    [string]$PythonPath = "python"
)

# Funzione per l'output dettagliato
function Write-VerboseLog {
    param([string]$Message)
    if ($Verbose) {
        Write-Host $Message -ForegroundColor Cyan
    }
}

# Verifica compatibilità Python
try {
    $pythonVersion = & $PythonPath -c "import sys; print(sys.version_info.major, sys.version_info.minor)"
    $versionCheck = $pythonVersion -split ' '
    
    if ([int]$versionCheck[0] -lt 3 -or ([int]$versionCheck[0] -eq 3 -and [int]$versionCheck[1] -lt 8)) {
        throw "Python 3.8+ richiesto"
    }
    
    Write-VerboseLog "Versione Python verificata: $pythonVersion"
}
catch {
    Write-Host "Errore: $_" -ForegroundColor Red
    exit 1
}

# Preparazione ambiente
Write-VerboseLog "Preparazione ambiente Python..."

# Installazione pacchetto
try {
    & $PythonPath -m pip install --upgrade pip setuptools
    & $PythonPath -m pip install gene1799_core
    
    Write-Host "Installazione completata con successo!" -ForegroundColor Green
}
catch {
    Write-Host "Errore durante l'installazione: $_" -ForegroundColor Red
    exit 1
}

# Verifica installazione
try {
    $result = & $PythonPath -c "from gene1799_core.signing import signer; print(signer.get_signature_info())"
    Write-Host "Verifica installazione: OK" -ForegroundColor Green
    Write-Host "Dettagli certificato: $result" -ForegroundColor Green
}
catch {
    Write-Host "Verifica installazione fallita: $_" -ForegroundColor Red
    exit 1
}
