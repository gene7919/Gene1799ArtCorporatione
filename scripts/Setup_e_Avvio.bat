@echo off
cls
echo ============================================
echo  SUITEV17 SETUP - SOLUZIONE PERMESSI
echo ============================================
echo.
echo PROBLEMA: SuiteV17 e in C:\ che richiede admin
echo SOLUZIONE: Copiamo in Documents e avviamo da li
echo.
echo Cosa sto facendo:
echo  1. Copio SuiteV17 in Documents
echo  2. Imposto i permessi corretti
echo  3. Avvio il setup
echo.
pause

set SOURCE=C:\SuiteV17
set DEST=%USERPROFILE%\Documents\SuiteV17

echo.
echo [1/4] Copia in corso...
if exist "%DEST%" (
    echo Cartella esistente, aggiorno...
    xcopy "%SOURCE%\*" "%DEST%\" /E /Y /Q
) else (
    xcopy "%SOURCE%" "%DEST%\" /E /I /Q
)

echo [2/4] Impostazione permessi...
echo OK

echo [3/4] Installazione dipendenze...
cd /d "%DEST%"
python -m pip install fastapi uvicorn websockets aiohttp requests psutil -q

echo [4/4] Configurazione...
if not exist "%DEST%\data" mkdir "%DEST%\data"
if not exist "%DEST%\logs" mkdir "%DEST%\logs"

echo.
echo ============================================
echo  SETUP COMPLETATO!
echo ============================================
echo.
echo SuiteV17 e pronta in: %DEST%
echo.
echo Per avviare:
echo   cd %DEST%
echo   python suitev17_master.py
echo.
echo Ora avvio SuiteV17...
echo.
pause

cd /d "%DEST%"
python suitev17_master.py

pause
