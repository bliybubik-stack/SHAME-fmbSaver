@echo off
title FMB-SAVER Installer
echo ========================================
echo        FMB-SAVER INSTALLER
echo ========================================
echo.
echo Installing required packages...
echo.
pip install -r requirements.txt
echo.
echo ========================================
echo INSTALLATION COMPLETE!
echo ========================================
echo.
echo To run FMB-SAVER:
echo   1. Double-click run.bat
echo   2. Or type: python fmb_saver.py
echo.
pause
