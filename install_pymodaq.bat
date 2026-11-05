@echo off
REM Lance install_pymodaq.ps1 sans être bloqué par la politique d'exécution PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install_pymodaq.ps1" %*
pause
