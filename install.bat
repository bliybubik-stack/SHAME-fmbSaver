@echo off
title FMB-SAVER Installer
color 0A
echo ========================================
echo        FMB-SAVER INSTALLER
echo ========================================
echo.

:: Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python is NOT installed!
    echo.
    echo Please install Python from: https://www.python.org/downloads/
    echo.
    echo IMPORTANT: During installation, check "Add Python to PATH"
    echo.
    pause
    exit /b
)

echo [OK] Python found!
echo.

:: Check if pip works
python -m pip --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] pip is not working!
    echo Trying to fix...
    python -m ensurepip
)

echo.
echo Installing required packages...
echo.

python -m pip install opencv-python mss pynput pillow numpy

echo.
echo ========================================
echo INSTALLATION COMPLETE!
echo ========================================
echo.
echo To run FMB-SAVER:
echo   Double-click run.bat
echo.
pause
