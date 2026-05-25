@echo off
setlocal EnableExtensions
cd /d "%~dp0\.."
powershell -NoProfile -ExecutionPolicy Bypass -File "tests\smoke.ps1" %*
if errorlevel 1 exit /b 1
