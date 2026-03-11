#Requires -Version 5.1
<#
.SYNOPSIS
    Installs rainbow-csv.nvim into the Neovim pack directory on Windows.
#>

$ErrorActionPreference = 'Stop'
$PluginName = 'rainbow-csv.nvim'
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Determine install target
$CandidatePaths = @(
    (Join-Path $env:LOCALAPPDATA 'nvim-data\site\pack\plugins\start'),
    (Join-Path $env:LOCALAPPDATA 'nvim\pack\plugins\start')
)

$PackDir = $null
foreach ($candidate in $CandidatePaths) {
    $parentCheck = Split-Path $candidate -Parent | Split-Path -Parent | Split-Path -Parent
    if (Test-Path $parentCheck) {
        $PackDir = $candidate
        break
    }
}

if (-not $PackDir) {
    Write-Error @"
Could not locate a Neovim config directory.
Ensure Neovim is installed and one of these exists:
  $($CandidatePaths -join "`n  ")
"@
    exit 1
}

$Target = Join-Path $PackDir $PluginName

Write-Host "Installing $PluginName"
Write-Host "  Source:  $ScriptDir"
Write-Host "  Target:  $Target"

# Remove previous install if present
if (Test-Path $Target) {
    Write-Host '  Removing existing installation...'
    Remove-Item -Recurse -Force $Target
}

# Create pack directory if needed
if (-not (Test-Path $PackDir)) {
    New-Item -ItemType Directory -Path $PackDir -Force | Out-Null
}

# Copy plugin files
Copy-Item -Recurse -Path $ScriptDir -Destination $Target

# Clean up non-plugin files from the installed copy
$CleanupFiles = @('install.sh', 'install.ps1')
foreach ($f in $CleanupFiles) {
    $fp = Join-Path $Target $f
    if (Test-Path $fp) { Remove-Item -Force $fp }
}

Write-Host ''
Write-Host 'Done. Restart Neovim or run :packloadall to activate.'
Write-Host 'The plugin auto-enables on .csv, .tsv, and .psv files.'
Write-Host 'For other files, run :RainbowCsvEnable manually.'
