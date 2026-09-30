# start-office-windows.ps1 — start Agent Office in the background on Windows (no console windows).
# Run at login by the "Agent Office" shortcut in the Startup folder (see install-startup-windows.ps1).
#   .\start-office-windows.ps1         start server (3334) + UI (3333) + chat watcher, if not already up
#   .\start-office-windows.ps1 -Stop   stop them
# Logs: %USERPROFILE%\.agent-office\*.log
param([switch]$Stop)

$Root = Split-Path -Parent $PSScriptRoot
$LogDir = Join-Path $env:USERPROFILE '.agent-office'
New-Item -ItemType Directory -Force $LogDir | Out-Null

# Every process we start has the project path in its command line — that is how -Stop finds them.
function Get-OfficeProcesses {
  Get-CimInstance Win32_Process -Filter "Name='node.exe' OR Name='bash.exe'" |
    Where-Object { $_.CommandLine -like "*AgentOffice*" -and $_.CommandLine -notlike "*agent-tracker*" }
}

if ($Stop) {
  Get-OfficeProcesses | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  'Agent Office stopped.'
  return
}

function Test-Up([string]$Url) {
  try { Invoke-WebRequest $Url -UseBasicParsing -TimeoutSec 2 | Out-Null; $true } catch { $false }
}

$Node = (Get-Command node -ErrorAction Stop).Source
$Bash = 'C:\Program Files\Git\bin\bash.exe'

if (-not (Test-Up 'http://127.0.0.1:3334/health')) {
  Start-Process $Node -ArgumentList "`"$Root\server\index.js`"" -WorkingDirectory $Root -WindowStyle Hidden `
    -RedirectStandardOutput "$LogDir\server.log" -RedirectStandardError "$LogDir\server.err.log"
}

if (-not (Test-Up 'http://localhost:3333')) {
  Start-Process $Node -ArgumentList "`"$Root\node_modules\vite\bin\vite.js`" --port 3333 --strictPort" -WorkingDirectory $Root -WindowStyle Hidden `
    -RedirectStandardOutput "$LogDir\ui.log" -RedirectStandardError "$LogDir\ui.err.log"
}

# Chat AI watcher: polls every 8s; only calls `claude -p` when the AI toggle in the UI is ON (default OFF)
$watcherRunning = Get-OfficeProcesses | Where-Object { $_.CommandLine -like '*chat-ai-watcher*' }
if (-not $watcherRunning -and (Test-Path $Bash)) {
  Start-Process $Bash -ArgumentList "`"$Root/scripts/chat-ai-watcher.sh`"" -WorkingDirectory $Root -WindowStyle Hidden `
    -RedirectStandardOutput "$LogDir\chat-ai.log" -RedirectStandardError "$LogDir\chat-ai.err.log"
}

'Agent Office running: http://localhost:3333'
