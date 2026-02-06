# Script di Test Sistema Completo
# Comprehensive System Test Script

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "        TEST SISTEMA COMPLETO" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Funzioni di utilità
function Write-Success {
    param($Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param($Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param($Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

function Write-Section {
    param($Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Magenta
}

# Test Software Installato
function Test-Software {
    Write-Section "TEST SOFTWARE INSTALLATO"
    
    $software = @(
        @{Name="Python"; Command="python --version"},
        @{Name="Node.js"; Command="node --version"},
        @{Name="Git"; Command="git --version"},
        @{Name="VS Code"; Command="code --version"},
        @{Name="Chocolatey"; Command="choco --version"}
    )
    
    foreach ($app in $software) {
        try {
            $version = Invoke-Expression $app.Command 2>$null
            if ($version) {
                Write-Success "$($app.Name): $version"
            } else {
                Write-Error "$($app.Name): Non funziona"
            }
        } catch {
            Write-Error "$($app.Name): Non installato o non nel PATH"
        }
    }
}

# Test Dischi
function Test-Disks {
    Write-Section "TEST DISCHI SISTEMA"
    
    $disks = Get-WmiObject -Class Win32_LogicalDisk
    
    foreach ($disk in $disks) {
        $driveLetter = $disk.DeviceID
        $totalSizeGB = [Math]::Round($disk.Size / 1GB, 2)
        $freeSizeGB = [Math]::Round($disk.FreeSpace / 1GB, 2)
        $usedSizeGB = [Math]::Round(($disk.Size - $disk.FreeSpace) / 1GB, 2)
        $freePercent = [Math]::Round(($disk.FreeSpace / $disk.Size) * 100, 1)
        
        $driveType = switch ($disk.DriveType) {
            2 { "Floppy" }
            3 { "Disco Fisso" }
            4 { "Rete" }
            5 { "CD/DVD" }
            6 { "RAM" }
            default { "Sconosciuto" }
        }
        
        Write-Host ""
        Write-Host "🖥️  DISCO $driveLetter" -ForegroundColor White
        Write-Host "   Tipo: $driveType"
        Write-Host "   Totale: $totalSizeGB GB"
        Write-Host "   Utilizzato: $usedSizeGB GB"
        Write-Host "   Libero: $freeSizeGB GB ($freePercent%)"
        
        if ($freePercent -lt 10) {
            Write-Error "   ⚠️ ATTENZIONE: Spazio insufficiente!"
        } elseif ($freePercent -lt 20) {
            Write-Info "   ⚠️ Spazio in esaurimento"
        } else {
            Write-Success "   ✓ Spazio sufficiente"
        }
    }
}

# Test Connettività
function Test-Connectivity {
    Write-Section "TEST CONNETTIVITÀ INTERNET"
    
    $sites = @("google.com", "github.com", "microsoft.com")
    
    foreach ($site in $sites) {
        try {
            $result = Test-Connection -ComputerName $site -Count 1 -Quiet
            if ($result) {
                Write-Success "Connessione a $site: OK"
            } else {
                Write-Error "Connessione a $site: FALLITA"
            }
        } catch {
            Write-Error "Errore test connessione a $site"
        }
    }
}

# Test Servizi Sistema
function Test-SystemServices {
    Write-Section "TEST SERVIZI SISTEMA"
    
    $services = @(
        "Windows Update",
        "Windows Defender",
        "BITS", 
        "Themes"
    )
    
    foreach ($serviceName in $services) {
        try {
            $service = Get-Service -DisplayName "*$serviceName*" -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($service) {
                if ($service.Status -eq "Running") {
                    Write-Success "$($service.DisplayName): In esecuzione"
                } else {
                    Write-Info "$($service.DisplayName): $($service.Status)"
                }
            } else {
                Write-Info "$serviceName: Servizio non trovato"
            }
        } catch {
            Write-Error "Errore controllo servizio $serviceName"
        }
    }
}

# Test Performance Sistema
function Test-SystemPerformance {
    Write-Section "TEST PERFORMANCE SISTEMA"
    
    # CPU
    $cpu = Get-WmiObject Win32_Processor
    Write-Host "🔧 CPU: $($cpu.Name)"
    Write-Host "   Core: $($cpu.NumberOfCores)"
    Write-Host "   Thread logici: $($cpu.NumberOfLogicalProcessors)"
    
    # RAM
    $ram = Get-WmiObject Win32_ComputerSystem
    $totalRAM = [Math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    Write-Host "🧠 RAM Totale: $totalRAM GB"
    
    # Memoria disponibile
    $availableRAM = Get-Counter "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 1
    $availableRAMGB = [Math]::Round($availableRAM.CounterSamples[0].CookedValue / 1024, 2)
    $usedRAMGB = [Math]::Round($totalRAM - $availableRAMGB, 2)
    
    Write-Host "   RAM Utilizzata: $usedRAMGB GB"
    Write-Host "   RAM Disponibile: $availableRAMGB GB"
    
    # Sistema Operativo
    $os = Get-WmiObject Win32_OperatingSystem
    Write-Host "💻 Sistema: $($os.Caption)"
    Write-Host "   Versione: $($os.Version)"
    Write-Host "   Architettura: $($os.OSArchitecture)"
    
    # Uptime
    $uptime = (Get-Date) - $os.ConvertToDateTime($os.LastBootUpTime)
    Write-Host "⏰ Sistema acceso da: $($uptime.Days) giorni, $($uptime.Hours) ore"
}

# Test File System
function Test-FileSystem {
    Write-Section "TEST ACCESSO FILE SYSTEM"
    
    $testPaths = @(
        "C:\Users\$env:USERNAME\Desktop",
        "C:\Users\$env:USERNAME\Documents", 
        "C:\Users\$env:USERNAME\Downloads",
        "C:\Windows\System32",
        "C:\Program Files"
    )
    
    foreach ($path in $testPaths) {
        if (Test-Path $path) {
            Write-Success "Accesso a $path: OK"
        } else {
            Write-Error "Accesso a $path: NEGATO"
        }
    }
}

# Test Installazione Python Packages
function Test-PythonPackages {
    Write-Section "TEST PACCHETTI PYTHON"
    
    $packages = @("requests", "numpy", "pandas", "matplotlib")
    
    foreach ($package in $packages) {
        try {
            $result = python -c "import $package; print('$package OK')" 2>$null
            if ($result -like "*OK*") {
                Write-Success "Pacchetto Python $package: Installato"
            } else {
                Write-Info "Pacchetto Python $package: Non installato"
            }
        } catch {
            Write-Error "Errore test pacchetto $package"
        }
    }
}

# Genera Report
function Generate-Report {
    Write-Section "GENERAZIONE REPORT"
    
    $reportPath = "$env:USERPROFILE\Desktop\SystemTest-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
    
    $reportContent = @"
===============================================
        REPORT TEST SISTEMA COMPLETO
        Data: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
===============================================

COMPUTER: $env:COMPUTERNAME
UTENTE: $env:USERNAME
SISTEMA: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption)

SOFTWARE TESTATO:
- Python: $(try { python --version } catch { "Non installato" })
- Node.js: $(try { node --version } catch { "Non installato" })
- Git: $(try { git --version } catch { "Non installato" })
- VS Code: $(try { code --version | Select-Object -First 1 } catch { "Non installato" })
- Chocolatey: $(try { choco --version } catch { "Non installato" })

DISCHI SISTEMA:
$(Get-WmiObject Win32_LogicalDisk | ForEach-Object {
    "$($_.DeviceID) - $([Math]::Round($_.Size/1GB,2)) GB totali, $([Math]::Round($_.FreeSpace/1GB,2)) GB liberi"
})

HARDWARE:
CPU: $(Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name)
RAM: $([Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB,2)) GB

Test completato con successo!
"@
    
    $reportContent | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Success "Report salvato in: $reportPath"
    
    return $reportPath
}

# Menu principale
function Show-TestMenu {
    do {
        Write-Host ""
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host "           MENU TEST SISTEMA" -ForegroundColor Cyan
        Write-Host "===============================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "1) Test Software Installato" -ForegroundColor White
        Write-Host "2) Test Dischi (C, D, E, etc.)" -ForegroundColor White
        Write-Host "3) Test Connettività Internet" -ForegroundColor White
        Write-Host "4) Test Servizi Sistema" -ForegroundColor White
        Write-Host "5) Test Performance Sistema" -ForegroundColor White
        Write-Host "6) Test File System" -ForegroundColor White
        Write-Host "7) Test Pacchetti Python" -ForegroundColor White
        Write-Host "8) ✅ TEST COMPLETO (Tutto)" -ForegroundColor Green
        Write-Host "9) 📄 Genera Report Desktop" -ForegroundColor Yellow
        Write-Host "0) Esci" -ForegroundColor White
        Write-Host ""
        
        $choice = Read-Host "Seleziona opzione [0-9]"
        
        switch ($choice) {
            1 { Test-Software }
            2 { Test-Disks }
            3 { Test-Connectivity }
            4 { Test-SystemServices }
            5 { Test-SystemPerformance }
            6 { Test-FileSystem }
            7 { Test-PythonPackages }
            8 { 
                Test-Software
                Test-Disks
                Test-Connectivity
                Test-SystemServices
                Test-SystemPerformance
                Test-FileSystem  
                Test-PythonPackages
                Write-Host ""
                Write-Host "🎉 TEST COMPLETO TERMINATO!" -ForegroundColor Green
            }
            9 { 
                $reportPath = Generate-Report
                Write-Host ""
                Write-Info "Vuoi aprire il report? (s/n)"
                $openReport = Read-Host
                if ($openReport -eq "s" -or $openReport -eq "S") {
                    notepad $reportPath
                }
            }
            0 { 
                Write-Host "Test terminato!" -ForegroundColor Green
                return 
            }
            default { 
                Write-Error "Scelta non valida!" 
            }
        }
        
        if ($choice -ne 0) {
            Write-Host ""
            Write-Host "Premi un tasto per continuare..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
        
    } while ($choice -ne 0)
}

# Esegue il menu
Show-TestMenu
