#Requires -Version 5.1
<#
.SYNOPSIS
    Installs Neovim CSV plugins into the Neovim pack directory on Windows.
.PARAMETER Only
    Install a single plugin: 'rainbow-csv' or 'csv-sql'
#>
param(
    [ValidateSet('rainbow-csv', 'csv-sql')]
    [string]$Only
)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$Plugins   = @('rainbow-csv.nvim', 'csv-sql.nvim')

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

if (-not (Test-Path $PackDir)) {
    New-Item -ItemType Directory -Path $PackDir -Force | Out-Null
}

function Install-Plugin {
    param([string]$Name)

    $Source = Join-Path $ScriptDir $Name
    $Target = Join-Path $PackDir $Name

    if (-not (Test-Path $Source)) {
        Write-Error "Plugin directory not found: $Source"
        return
    }

    Write-Host "Installing $Name"
    Write-Host "  Source:  $Source"
    Write-Host "  Target:  $Target"

    if (Test-Path $Target) {
        Write-Host '  Removing existing installation...'
        Remove-Item -Recurse -Force $Target
    }

    Copy-Item -Recurse -Path $Source -Destination $Target
    Write-Host '  Done.'
    Write-Host ''
}

if ($Only) {
    Install-Plugin -Name "$Only.nvim"
} else {
    foreach ($plugin in $Plugins) {
        Install-Plugin -Name $plugin
    }
}

Write-Host 'Restart Neovim or run :packloadall to activate.'
