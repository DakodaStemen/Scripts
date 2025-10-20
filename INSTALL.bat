@echo off
echo ================================================
echo  AS7RA'S PC Health Check - Quick Run
echo ================================================
echo.

:: Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Error: This script requires Administrator privileges!
    echo.
    echo Please right-click this file and select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Running PC health check...
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0PowerShell-Toolkit\System-Utilities\PC-Health-Check.ps1"

echo.
echo Health check complete!
pause
    