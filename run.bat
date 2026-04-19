@echo off
title FMB-SAVER
color 0A
echo Starting FMB-SAVER...
python fmb_saver.py
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to start!
    echo Make sure you ran install.bat first
    echo.
    pause
)
