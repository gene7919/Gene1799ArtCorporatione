Write-Host "=== AVVIO TUTTE LE APPLICAZIONI SUITEV17 ===" -ForegroundColor Cyan
Write-Host ""

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-control-room.ps1"
Write-Host "Avviato: Control Room" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-legal-sign.ps1"
Write-Host "Avviato: Legal Sign" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-desktop-app.ps1"
Write-Host "Avviato: Desktop App" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-hub-electron.ps1"
Write-Host "Avviato: Hub Electron" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-genstudio.ps1"
Write-Host "Avviato: GenStudio" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-opscontrol.ps1"
Write-Host "Avviato: OpsControl" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-suitev17-app.ps1"
Write-Host "Avviato: SuiteV17 App" -ForegroundColor Green

Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File C:\SuiteV17\launchers\start-aihub.ps1"
Write-Host "Avviato: AIHub" -ForegroundColor Green

Write-Host ""
Write-Host "=== TUTTE LE APPLICAZIONI AVVIATE ===" -ForegroundColor Cyan
