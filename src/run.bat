@echo off
setlocal enabledelayedexpansion

:: Get the path from zb.exe
set ZB_PATH=%~dp0zb.exe
for /f "delims=" %%d in ('%ZB_PATH% %*') do set "TARGET_DIR=%%d"

:: Check if we got a directory path
if not defined TARGET_DIR exit /b 1

:: Special case for help/listing commands
echo %TARGET_DIR%|findstr /r "^zb -" >nul && (
    echo %TARGET_DIR%
    exit /b 0
)

:: Try to change directory
cd /d "%TARGET_DIR%" 2>nul
if errorlevel 1 (
    echo Failed to cd to: %TARGET_DIR%
    exit /b 1
)

:: Success - print and stay in new directory
echo Jumped to: %TARGET_DIR%
