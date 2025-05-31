@echo off
setlocal enabledelayedexpansion

set ZB_PATH=%~dp0zb.exe

:: Special case for help/list commands
for %%a in (-h --help -l --list) do (
    if "%~1"=="%%a" (
        %ZB_PATH% %*
        exit /b %errorlevel%
    )
)

:: Get directory from zb.exe
for /f "tokens=*" %%d in ('%ZB_PATH% %*') do (
    set "DIR=%%d"
    if "!DIR:~0,5!"=="error" (
        echo !DIR!
        exit /b 1
    )
    
    cd /d "!DIR!" 2>nul
    if errorlevel 1 (
        echo Failed to cd to: !DIR!
        exit /b 1
    )
    echo Jumped to: !DIR!
)
