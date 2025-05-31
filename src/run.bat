@echo off
setlocal
set ZB_PATH=%APPDATA%\zig-bookmarker\zb.exe

%ZB_PATH% %*
if errorlevel 1 return /b %errorlevel%

for /f "delims=" %%d in ('%ZB_PATH% %*') do (
    cd /d "%%d" 2>nul
    if errorlevel 1 (
        echo Failed to cd to: %%d
        return /b 1
    )
    echo Jumped to: %%d
)
