# Script di auto-installazione per Windows PowerShell
# Auto-installation script for Windows PowerShell

# Richiede esecuzione come amministratore
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Questo script deve essere eseguito come Amministratore!" -ForegroundColor Red
    Write-Host "Fai click destro su PowerShell e seleziona 'Esegui come amministratore'" -ForegroundColor Yellow
    pause
    exit 1
}

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

# Installa Chocolatey (gestore pacchetti per Windows)
function Install-Chocolatey {
    Write-Info "Installazione Chocolatey..."
    
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Ricarica l'ambiente
        refreshenv
        
        Write-Success "Chocolatey installato"
    } else {
        Write-Success "Chocolatey già installato"
    }
}

# Installa Winget (se non presente)
function Install-Winget {
    Write-Info "Verifica Winget..."
    
    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Info "Installazione Winget..."
        
        # Scarica e installa App Installer (include Winget)
        $progressPreference = 'silentlyContinue'
        $url = "https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $output = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"
        
        Invoke-WebRequest -Uri $url -OutFile $output
        Add-AppxPackage -Path $output
        
        Write-Success "Winget installato"
    } else {
        Write-Success "Winget già presente"
    }
}

# Installa applicazioni di base
function Install-BasicApps {
    Write-Info "Installazione applicazioni di base..."
    
    $apps = @(
        "git",
        "vscode",
        "googlechrome",
        "firefox",
        "7zip",
        "notepadplusplus",
        "vlc",
        "discord",
        "spotify",
        "steam"
    )
    
    foreach ($app in $apps) {
        try {
            choco install $app -y
            Write-Success "Installato: $app"
        } catch {
            Write-Error "Errore installazione: $app"
        }
    }
}

# Installa strumenti di sviluppo
function Install-DevTools {
    Write-Info "Installazione strumenti di sviluppo..."
    
    $devApps = @(
        "python",
        "nodejs",
        "docker-desktop",
        "postman",
        "fiddler",
        "wireshark",
        "putty",
        "winscp"
    )
    
    foreach ($app in $devApps) {
        try {
            choco install $app -y
            Write-Success "Installato: $app"
        } catch {
            Write-Error "Errore installazione: $app"
        }
    }
    
    # Installa pip packages
    Write-Info "Installazione pacchetti Python..."
    $pipPackages = @(
        "requests",
        "numpy",
        "pandas",
        "matplotlib",
        "flask",
        "fastapi",
        "beautifulsoup4",
        "selenium"
    )
    
    foreach ($package in $pipPackages) {
        try {
            pip install $package
            Write-Success "Installato pacchetto Python: $package"
        } catch {
            Write-Error "Errore installazione pacchetto Python: $package"
        }
    }
}

# Configura Git
function Setup-Git {
    Write-Info "Configurazione Git..."
    
    $gitName = Read-Host "Inserisci il tuo nome per Git"
    $gitEmail = Read-Host "Inserisci la tua email per Git"
    
    git config --global user.name $gitName
    git config --global user.email $gitEmail
    git config --global init.defaultBranch main
    
    Write-Success "Git configurato"
}

# Installa WSL2 (Windows Subsystem for Linux)
function Install-WSL {
    Write-Info "Installazione WSL2..."
    
    try {
        # Abilita WSL
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        
        # Abilita Virtual Machine Platform
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        
        # Imposta WSL2 come versione predefinita
        wsl --set-default-version 2
        
        # Installa Ubuntu
        wsl --install -d Ubuntu
        
        Write-Success "WSL2 installato (richiede riavvio)"
        Write-Info "Dopo il riavvio, apri Ubuntu dal menu Start per completare la configurazione"
        
    } catch {
        Write-Error "Errore installazione WSL2: $_"
    }
}

# Crea script di utilità
function Create-UtilityScripts {
    Write-Info "Creazione script di utilità..."
    
    $scriptDir = "$env:USERPROFILE\Scripts"
    if (!(Test-Path $scriptDir)) {
        New-Item -ItemType Directory -Path $scriptDir -Force
    }
    
    # Script per pulizia sistema
    $cleanupScript = @"
# Script di pulizia sistema
Write-Host "Pulizia sistema in corso..." -ForegroundColor Green

# Svuota cestino
Clear-RecycleBin -Force

# Pulizia file temporanei
Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Pulizia cache browser
$chromeCache = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
if (Test-Path $chromeCache) {
    Remove-Item -Path "$chromeCache\*" -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Pulizia completata!" -ForegroundColor Green
"@
    
    $cleanupScript | Out-File -FilePath "$scriptDir\Cleanup-System.ps1" -Encoding UTF8
    
    # Script info sistema
    $systemInfoScript = @"
# Script informazioni sistema
Write-Host "=== INFORMAZIONI SISTEMA ===" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME"
Write-Host "Utente: $env:USERNAME" 
Write-Host "OS: $(Get-WmiObject Win32_OperatingSystem | Select-Object -ExpandProperty Caption)"
Write-Host "Processore: $(Get-WmiObject Win32_Processor | Select-Object -ExpandProperty Name)"
Write-Host "RAM: $([Math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB, 2)) GB"
Write-Host "Spazio disco C:: $([Math]::Round((Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace/1GB, 2)) GB liberi"
Write-Host "IP Address: $((Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi*" | Select-Object -First 1).IPAddress)"
"@
    
    $systemInfoScript | Out-File -FilePath "$scriptDir\Get-SystemInfo.ps1" -Encoding UTF8
    
    Write-Success "Script creati in $scriptDir"
}

# Configura PowerShell Profile
function Setup-PowerShellProfile {
    Write-Info "Configurazione PowerShell Profile..."
    
    $profileContent = @"
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
    notepad $PROFILE 
}

# Messaggio di benvenuto
Write-Host "PowerShell Profile caricato!" -ForegroundColor Green
Write-Host "Usa 'Get-Help about_profiles' per saperne di più sui profili." -ForegroundColor Yellow
"@
    
    if (!(Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force
    }
    
    $profileContent | Out-File -FilePath $PROFILE -Encoding UTF8
    
    Write-Success "PowerShell Profile configurato"
}

# Menu principale
function Show-Menu {
    Clear-Host
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host "     AUTO INSTALLER WINDOWS" -ForegroundColor Cyan  
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1) Installa Chocolatey" -ForegroundColor White
    Write-Host "2) Installa Winget" -ForegroundColor White
    Write-Host "3) Installa applicazioni di base" -ForegroundColor White
    Write-Host "4) Installa strumenti di sviluppo" -ForegroundColor White
    Write-Host "5) Configura Git" -ForegroundColor White
    Write-Host "6) Installa WSL2" -ForegroundColor White
    Write-Host "7) Crea script di utilità" -ForegroundColor White
    Write-Host "8) Configura PowerShell Profile" -ForegroundColor White
    Write-Host "9) Installa tutto" -ForegroundColor White
    Write-Host "0) Esci" -ForegroundColor White
    Write-Host ""
}

# Funzione principale
function Main {
    do {
        Show-Menu
        $choice = Read-Host "Seleziona opzione [0-9]"
        
        switch ($choice) {
            1 { Install-Chocolatey }
            2 { Install-Winget }
            3 { Install-BasicApps }
            4 { Install-DevTools }
            5 { Setup-Git }
            6 { Install-WSL }
            7 { Create-UtilityScripts }
            8 { Setup-PowerShellProfile }
            9 { 
                Install-Chocolatey
                Install-Winget  
                Install-BasicApps
                Install-DevTools
                Setup-Git
                Create-UtilityScripts
                Setup-PowerShellProfile
            }
            0 { 
                Write-Host "Arrivederci!" -ForegroundColor Green
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

# Esegue lo script
Main
