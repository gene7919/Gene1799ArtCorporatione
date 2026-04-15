@echo off
echo Creazione video di test 10 secondi...
cd /d "C:\SuiteV17"

:: Crea un video test 1280x720 10 secondi 30fps con FFmpeg
ffmpeg -y -f lavfi -i testsrc=duration=10:size=1280x720:rate=30 -pix_fmt yuv420p "Outputs\test_input.mp4"

if exist "Outputs\test_input.mp4" (
    echo.
    echo Video creato: C:\SuiteV17\Outputs\test_input.mp4
    echo.
) else (
    echo Errore creazione video
)
pause
