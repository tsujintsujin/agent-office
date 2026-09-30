# install-startup-windows.ps1 — add (or with -Remove, delete) the "Agent Office" login shortcut.
# Uses the per-user Startup folder, so no admin/UAC is needed.
param([switch]$Remove)

$Lnk = Join-Path ([Environment]::GetFolderPath('Startup')) 'Agent Office.lnk'

if ($Remove) {
  Remove-Item $Lnk -ErrorAction SilentlyContinue
  "Removed $Lnk"
  return
}

$Shell = New-Object -ComObject WScript.Shell
$S = $Shell.CreateShortcut($Lnk)
$S.TargetPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
$S.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSScriptRoot\start-office-windows.ps1`""
$S.WorkingDirectory = Split-Path -Parent $PSScriptRoot
$S.WindowStyle = 7  # minimized
$S.Description = 'Start Agent Office (http://localhost:3333) in the background'
$S.Save()
"Created $Lnk"
