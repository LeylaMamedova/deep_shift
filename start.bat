@echo off
cd /d "%~dp0"
set "NODE=node"
where node >nul 2>&1
if errorlevel 1 (
  if exist "%~dp0..\azimblox\.tools\node-v22.16.0-win-x64\node.exe" (
    set "NODE=%~dp0..\azimblox\.tools\node-v22.16.0-win-x64\node.exe"
  ) else (
    echo Node.js is required. Install it from https://nodejs.org
    pause
    exit /b 1
  )
)
if not defined PORT set PORT=5177
if not defined HOST set HOST=0.0.0.0
echo Starting Wirebound on http://localhost:%PORT%  (LAN: HOST %HOST%)
start "" "http://localhost:%PORT%"
"%NODE%" server/index.js
pause
