#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Quick Health Check Runner - Simplified launcher for PC-Health-Check.ps1
    
.DESCRIPTION
    A simplified launcher script that runs the comprehensive PC Health Check
    with commonly used parameters. This provides an easy entry point for users
    who want to quickly assess their system health.
    
.PARAMETER Quick
    Run a quick health check with minimal output
    
.PARAMETER Detailed
    Run a comprehensive health check with detailed logging
    
.PARAMETER Silent
    Run silently with output only to log files
    
.EXAMPLE
    .\Quick-Health-Check.ps1
    Runs standard health check with normal output
    
.EXAMPLE
    .\Quick-Health-Check.ps1 -Detailed
    Runs comprehensive check with detailed analysis
    
.NOTES
    Author: Dakoda Stemen
    Version: 1.0
    Created: 2024-10-21
    Repository: https://github.com/DakodaStemen/Scripts
    Requires: Administrator privileges for full functionality
    
.LINK
    https://github.com/DakodaStemen/Scripts
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$Quick,
    
    [Parameter(Mandatory=$false)]
    [switch]$Detailed,
    
    [Parameter(Mandatory=$false)]
    [switch]$Silent
)

# Script location and paths
$ScriptRoot = $PSScriptRoot
$HealthCheckScript = Join-Path $ScriptRoot "System-Utilities\PC-Health-Check.ps1"

# Verify the main script exists
if (-not (Test-Path $HealthCheckScript)) {
    Write-Error "PC-Health-Check.ps1 not found at: $HealthCheckScript"
    Write-Host "Please ensure you're running this from the PowerShell-Toolkit directory" -ForegroundColor Yellow
    exit 1
}

# Display banner
Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║                                                        ║" -ForegroundColor Cyan
Write-Host "║               Quick PC Health Check                    ║" -ForegroundColor Cyan
Write-Host "║            PowerShell Toolkit Launcher                ║" -ForegroundColor Cyan
Write-Host "║                                                        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check for admin privileges
$currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
$isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Running without Administrator privileges"
    Write-Host "Some system checks may be limited. For full functionality, run as Administrator." -ForegroundColor Yellow
    Write-Host ""
}

# Prepare parameters for the main script
$scriptParams = @{}

if ($Quick) {
    $scriptParams['Quick'] = $true
    Write-Host "→ Running quick health check..." -ForegroundColor Green
} elseif ($Detailed) {
    $scriptParams['Detailed'] = $true
    Write-Host "→ Running detailed health analysis..." -ForegroundColor Green
} elseif ($Silent) {
    $scriptParams['Silent'] = $true
    Write-Host "→ Running silent check (output to logs only)..." -ForegroundColor Green
} else {
    Write-Host "→ Running standard health check..." -ForegroundColor Green
}

Write-Host ""

# Execute the main health check script
try {
    & $HealthCheckScript @scriptParams
    
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                Health Check Complete                   ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    # Show log location
    $LogsPath = Join-Path $ScriptRoot "..\Logs"
    if (Test-Path $LogsPath) {
        Write-Host ""
        Write-Host "Detailed results saved to: $LogsPath" -ForegroundColor Gray
    }
    
} catch {
    Write-Error "Failed to execute health check: $($_.Exception.Message)"
    exit 1
}

# Pause if running interactively (not from another script)
if ([Environment]::UserInteractive -and -not $Silent) {
    Write-Host ""
    Read-Host "Press Enter to exit"
}