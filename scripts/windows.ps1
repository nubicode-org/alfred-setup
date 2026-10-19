#Requires -Version 5.1
<#
.SYNOPSIS
  Prepare a Windows PC for the Alfred Learning roadmap.

.DESCRIPTION
  Turns on WSL2 with Ubuntu, and installs the Windows-side apps with winget:
  Windows Terminal, VS Code (with its WSL extension), Git for Windows and Docker Desktop.
  Everything else - Git, Python, Go, Node.js, kubectl and the rest - is installed inside
  Ubuntu by scripts/linux.sh, because the courses teach the Linux tools that servers and
  CI runners use. Safe to run more than once: anything already installed is skipped.

  Run it from an administrator PowerShell window:
    powershell -ExecutionPolicy Bypass -File .\scripts\windows.ps1

.PARAMETER DryRun
  Show what would be installed and the exact commands, change nothing.

.PARAMETER Yes
  Do not ask for confirmation.

.PARAMETER NoDocker
  Skip Docker Desktop (you will install Docker Engine inside Ubuntu instead).
#>
[CmdletBinding()]
param(
  [switch]$DryRun,
  [switch]$Yes,
  [switch]$NoDocker
)

$ErrorActionPreference = 'Stop'

function Write-Step([string]$Text) { Write-Host ''; Write-Host "==> $Text" -ForegroundColor Cyan }
function Write-Info([string]$Text) { Write-Host "    $Text" }
function Write-Skip([string]$Text) { Write-Host "    skip  $Text" -ForegroundColor DarkGray }
function Write-Done([string]$Text) { if (-not $DryRun) { Write-Host "    done  $Text" -ForegroundColor Green } }
function Write-Warn([string]$Text) { Write-Host "    warn  $Text" -ForegroundColor Yellow }

# Every change goes through Invoke-Change, so -DryRun shows the exact commands.
function Invoke-Change([string]$Exe, [string[]]$Arguments) {
  $line = "$Exe $($Arguments -join ' ')"
  if ($DryRun) { Write-Host "    would run: $line" -ForegroundColor DarkGray; return 0 }
  Write-Host "    > $line" -ForegroundColor DarkGray
  & $Exe @Arguments | Out-Host
  return $LASTEXITCODE
}

$packages = @(
  @{ Id = 'Microsoft.WindowsTerminal'; Name = 'Windows Terminal' },
  @{ Id = 'Microsoft.VisualStudioCode'; Name = 'VS Code' },
  @{ Id = 'Git.Git'; Name = 'Git for Windows (for Git Credential Manager and Windows-side repositories)' }
)
if (-not $NoDocker) {
  $packages += @{ Id = 'Docker.DockerDesktop'; Name = 'Docker Desktop (free for personal use and small businesses; see docs/windows.md)' }
}

# --- Preconditions -----------------------------------------------------------------------

$build = [System.Environment]::OSVersion.Version.Build
if ($build -lt 19041) {
  Write-Host "This needs Windows 10 version 2004 (build 19041) or newer, or Windows 11. This PC is build $build." -ForegroundColor Red
  Write-Host 'Update Windows first: Settings > Windows Update.'
  exit 1
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
  [Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and -not $DryRun) {
  Write-Host 'Turning on WSL needs an administrator PowerShell.' -ForegroundColor Red
  Write-Host 'Right-click Windows PowerShell (or Terminal), choose "Run as administrator", and run this again.'
  exit 1
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
  Write-Host 'winget is not available.' -ForegroundColor Red
  Write-Host 'Install "App Installer" from the Microsoft Store (it provides winget), then run this again.'
  exit 1
}

function Test-WingetPackage([string]$Id) {
  $null = & winget list --id $Id --exact --accept-source-agreements --disable-interactivity 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Get-WslDistribution {
  if (-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)) { return @() }
  # wsl.exe writes UTF-16, which PowerShell 5.1 reads with NUL characters between letters.
  $raw = & wsl.exe --list --quiet 2>$null
  if ($LASTEXITCODE -ne 0 -or -not $raw) { return @() }
  return @($raw | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}

$distros = Get-WslDistribution
$hasUbuntu = [bool]($distros | Where-Object { $_ -like 'Ubuntu*' })

# --- Plan --------------------------------------------------------------------------------

Write-Step "Alfred Learning setup for Windows (build $build)"
if ($hasUbuntu) { Write-Skip "WSL2 with $(($distros | Where-Object { $_ -like 'Ubuntu*' })[0]) (already installed)" }
else { Write-Info 'turn on WSL2 and install Ubuntu (a restart may be needed)' }
$missing = @()
foreach ($p in $packages) {
  if (Test-WingetPackage $p.Id) { Write-Skip "$($p.Name) (already installed)" }
  else { Write-Info "install $($p.Name) with winget"; $missing += $p }
}
Write-Info 'install the VS Code WSL extension (skipped if present)'
Write-Info 'winget accepts each package''s license and the source agreement on your behalf.'
Write-Info 'Nothing here asks for an account or a token.'

if (-not $DryRun -and -not $Yes) {
  $answer = Read-Host "`nProceed? [y/N]"
  if ($answer -notmatch '^(y|yes)$') { Write-Host 'Nothing was changed.'; exit 0 }
}

# --- WSL2 and Ubuntu ---------------------------------------------------------------------

$restartNeeded = $false
Write-Step 'WSL2 and Ubuntu'
if ($hasUbuntu) {
  Write-Skip 'Ubuntu is installed'
  $null = Invoke-Change 'wsl.exe' @('--set-default-version', '2')
} else {
  $code = Invoke-Change 'wsl.exe' @('--install', '--distribution', 'Ubuntu', '--no-launch')
  if ($code -ne 0 -and -not $DryRun) {
    Write-Warn "wsl --install exited with $code. If it asked for a restart, restart and run this script again."
  }
  $restartNeeded = $true
  Write-Done 'WSL2 and Ubuntu'
}

# --- Windows-side apps -------------------------------------------------------------------

Write-Step 'Windows apps'
if ($missing.Count -eq 0) { Write-Skip 'all present' }
foreach ($p in $missing) {
  $code = Invoke-Change 'winget' @('install', '--id', $p.Id, '--exact', '--source', 'winget',
    '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
  if ($code -ne 0 -and -not $DryRun) { Write-Warn "winget could not install $($p.Id) (exit $code). Install it by hand: docs/windows.md" }
  else { Write-Done $p.Name }
}

# --- VS Code WSL extension ---------------------------------------------------------------

Write-Step 'VS Code WSL extension'
$codeCmd = @(
  (Get-Command code -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
  "$env:LOCALAPPDATA\Programs\Microsoft VS Code\bin\code.cmd",
  "$env:ProgramFiles\Microsoft VS Code\bin\code.cmd"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $codeCmd) {
  if ($DryRun) { Write-Info 'would install ms-vscode-remote.remote-wsl once VS Code is present' }
  else { Write-Warn 'VS Code is not found yet. Open a new PowerShell and run: code --install-extension ms-vscode-remote.remote-wsl' }
} elseif ((& $codeCmd --list-extensions) -contains 'ms-vscode-remote.remote-wsl') {
  Write-Skip 'ms-vscode-remote.remote-wsl'
} else {
  $null = Invoke-Change $codeCmd @('--install-extension', 'ms-vscode-remote.remote-wsl')
  Write-Done 'ms-vscode-remote.remote-wsl'
}
Write-Info 'The other extensions install inside Ubuntu when you run scripts/linux.sh there.'

if ($DryRun) { Write-Step 'Dry run finished. Nothing was changed.'; exit 0 }

# --- Next steps --------------------------------------------------------------------------

Write-Step 'Next steps'
$n = 1
if ($restartNeeded) { Write-Info "$n. Restart Windows to finish turning on WSL."; $n++ }
Write-Info "$n. Open Ubuntu from the Start menu and create your Linux user name and password."; $n++
if (-not $NoDocker) {
  Write-Info "$n. Open Docker Desktop, accept its terms, then Settings > Resources > WSL integration > turn on Ubuntu."; $n++
}
Write-Info "$n. In the Ubuntu window, run:"; $n++
Write-Info '     git clone https://github.com/nubicode-org/alfred-setup.git ~/alfred-setup'
Write-Info '     cd ~/alfred-setup && ./scripts/linux.sh'
Write-Info "$n. Then check everything from Ubuntu: ./scripts/verify.sh"
