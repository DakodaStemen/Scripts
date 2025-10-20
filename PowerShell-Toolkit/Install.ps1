#Requires -RunAsAdministrator

<#
.SYNOPSIS
    PowerShell Toolkit Installer
.DESCRIPTION
    Installs and configures the PowerShell Toolkit suite
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator privileges
#>

$ToolkitPath = $PSScriptRoot

function Write-Banner {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                        ║" -ForegroundColor Cyan
    Write-Host "║        PowerShell Toolkit - Installation              ║" -ForegroundColor Cyan
    Write-Host "║        Professional Automation Scripts                ║" -ForegroundColor Cyan
    Write-Host "║                                                        ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-AdminPrivileges {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-ExecutionPolicyIfNeeded {
    $currentPolicy = Get-ExecutionPolicy
    if ($currentPolicy -eq "Restricted" -or $currentPolicy -eq "AllSigned") {
        Write-Host "→ Setting execution policy..." -ForegroundColor Yellow
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Host "✓ Execution policy updated" -ForegroundColor Green
    } else {
        Write-Host "✓ Execution policy is already configured" -ForegroundColor Green
    }
}

function Add-ToolkitToPath {
    $envPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($envPath -notlike "*$ToolkitPath*") {
        Write-Host "→ Adding toolkit to PATH..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("Path", "$envPath;$ToolkitPath", "User")
        Write-Host "✓ Toolkit added to PATH" -ForegroundColor Green
        Write-Host "  Restart terminal for PATH changes to take effect" -ForegroundColor Gray
    } else {
        Write-Host "✓ Toolkit already in PATH" -ForegroundColor Green
    }
}

function Show-AvailableScripts {
    Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║          Available Scripts" -ForegroundColor Green -NoNewline
    Write-Host "                           ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    
    $categories = @(
        @{Name="System Utilities"; Path="System-Utilities"},
        @{Name="Development Tools"; Path="Development-Tools"},
        @{Name="File Management"; Path="File-Management"},
        @{Name="Network Tools"; Path="Network-Tools"},
        @{Name="Productivity"; Path="Productivity"},
        @{Name="Web & Portfolio"; Path="Web-Portfolio"}
    )
    
    foreach ($cat in $categories) {
        $catPath = Join-Path $ToolkitPath $cat.Path
        if (Test-Path $catPath) {
            $scripts = Get-ChildItem -Path $catPath -Filter "*.ps1" | Measure-Object
            Write-Host "  $($cat.Name): " -NoNewline -ForegroundColor Cyan
            Write-Host "$($scripts.Count) scripts" -ForegroundColor White
        }
    }
}

function Test-Dependencies {
    Write-Host "`n→ Checking dependencies..." -ForegroundColor Yellow
    
    # Check PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -ge 5) {
        Write-Host "  ✓ PowerShell $($psVersion.Major).$($psVersion.Minor)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ PowerShell 5.1+ required" -ForegroundColor Red
    }
    
    # Check optional dependencies
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git) {
        Write-Host "  ✓ Git installed" -ForegroundColor Green
    } else {
        Write-Host "  ℹ Git not found (optional - required for git scripts)" -ForegroundColor Yellow
    }
    
    $node = Get-Command node -ErrorAction SilentlyContinue
    if ($node) {
        Write-Host "  ✓ Node.js installed" -ForegroundColor Green
    } else {
        Write-Host "  ℹ Node.js not found (optional - required for web dev scripts)" -ForegroundColor Yellow
    }
}

# Main Installation
Write-Banner

if (-not (Test-AdminPrivileges)) {
    Write-Host "⚠ Warning: Not running as Administrator" -ForegroundColor Yellow
    Write-Host "Some features may require admin privileges" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Installing PowerShell Toolkit..." -ForegroundColor Cyan
Write-Host "Installation path: $ToolkitPath" -ForegroundColor Gray
Write-Host ""

# Step 1: Execution Policy
Set-ExecutionPolicyIfNeeded

# Step 2: Add to PATH
Add-ToolkitToPath

# Step 3: Check dependencies
Test-Dependencies

# Step 4: Show available scripts
Show-AvailableScripts

# Installation complete
Write-Host "`n╔════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║        Installation Complete!" -ForegroundColor Green -NoNewline
Write-Host "                           ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Quick Start:" -ForegroundColor Cyan
Write-Host "  1. View README.md for full documentation" -ForegroundColor White
Write-Host "  2. Navigate to any category folder" -ForegroundColor White
Write-Host "  3. Run: Get-Help .\ScriptName.ps1 -Full" -ForegroundColor White
Write-Host ""
Write-Host "Examples:" -ForegroundColor Cyan
Write-Host '  .\System-Utilities\System-Info.ps1' -ForegroundColor Yellow
Write-Host '  .\File-Management\Smart-File-Organizer.ps1 -Path "C:\Downloads"' -ForegroundColor Yellow
Write-Host '  .\Development-Tools\Project-Initializer.ps1 -ProjectName "MyApp" -ProjectType React' -ForegroundColor Yellow
Write-Host ""
Write-Host "Documentation: https://github.com/yourusername/powershell-toolkit" -ForegroundColor Gray
Write-Host ""

# Pause for user
Read-Host "Press Enter to exit"

