#Requires -RunAsAdministrator

<#
.SYNOPSIS
    WiFi profile manager and network analyzer
.DESCRIPTION
    View, export, import, and manage WiFi profiles. Show network passwords.
.PARAMETER List
    List all saved WiFi profiles
.PARAMETER ShowPassword
    Show password for specific profile
.PARAMETER Export
    Export all profiles to folder
.PARAMETER Import
    Import profiles from folder
.PARAMETER Delete
    Delete specific profile
.PARAMETER Connect
    Connect to specific network
.EXAMPLE
    .\WiFi-Manager.ps1 -List
.EXAMPLE
    .\WiFi-Manager.ps1 -ShowPassword "MyNetwork"
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator privileges
#>

param(
    [switch]$List,
    [string]$ShowPassword,
    [string]$Export,
    [string]$Import,
    [string]$Delete,
    [string]$Connect
)

function Get-WiFiProfiles {
    $profiles = netsh wlan show profiles | Select-String "All User Profile" | ForEach-Object {
        $_.ToString().Split(':')[1].Trim()
    }
    return $profiles
}

function Get-WiFiPassword {
    param([string]$ProfileName)
    
    $keyContent = netsh wlan show profile name="$ProfileName" key=clear | Select-String "Key Content"
    
    if ($keyContent) {
        return $keyContent.ToString().Split(':')[1].Trim()
    }
    return $null
}

function Show-WiFiProfiles {
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         WiFi Profile Manager" -ForegroundColor Cyan -NoNewline
    Write-Host "                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    
    if ($profiles.Count -eq 0) {
        Write-Host "No saved WiFi profiles found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Saved WiFi Profiles ($($profiles.Count)):" -ForegroundColor Cyan
    Write-Host ""
    
    $counter = 1
    foreach ($profile in $profiles) {
        Write-Host "$counter. " -NoNewline -ForegroundColor Gray
        Write-Host $profile -ForegroundColor Green
        $counter++
    }
    
    Write-Host "`nUse -ShowPassword `"Name`" to view password" -ForegroundColor Gray
}

function Export-WiFiProfiles {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
    
    Write-Host "Exporting WiFi profiles to: $Path" -ForegroundColor Cyan
    Write-Host ""
    
    $profiles = Get-WiFiProfiles
    $exported = 0
    
    foreach ($profile in $profiles) {
        try {
            netsh wlan export profile name="$profile" folder="$Path" | Out-Null
            Write-Host "✓ Exported: $profile" -ForegroundColor Green
            $exported++
        }
        catch {
            Write-Host "✗ Failed: $profile" -ForegroundColor Red
        }
    }
    
    Write-Host "`n✓ Exported $exported profile(s)" -ForegroundColor Green
}

function Import-WiFiProfiles {
    param([string]$Path)
    
    if (-not (Test-Path $Path)) {
        Write-Host "✗ Path not found: $Path" -ForegroundColor Red
        return
    }
    
    $xmlFiles = Get-ChildItem -Path $Path -Filter "*.xml"
    
    if ($xmlFiles.Count -eq 0) {
        Write-Host "No WiFi profile XML files found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "Importing WiFi profiles from: $Path" -ForegroundColor Cyan
    Write-Host ""
    
    $imported = 0
    foreach ($file in $xmlFiles) {
        try {
            netsh wlan add profile filename="$($file.FullName)" | Out-Null
            Write-Host "✓ Imported: $($file.Name)" -ForegroundColor Green
            $imported++
        }
        catch {
            Write-Host "✗ Failed: $($file.Name)" -ForegroundColor Red
        }
    }
    
    Write-Host "`n✓ Imported $imported profile(s)" -ForegroundColor Green
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         WiFi Manager" -ForegroundColor Cyan -NoNewline
Write-Host "                            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($List) {
    Show-WiFiProfiles
}
elseif ($ShowPassword) {
    Write-Host ""
    Write-Host "Network: " -NoNewline
    Write-Host $ShowPassword -ForegroundColor Cyan
    
    $password = Get-WiFiPassword -ProfileName $ShowPassword
    
    if ($password) {
        Write-Host "Password: " -NoNewline
        Write-Host $password -ForegroundColor Green
    } else {
        Write-Host "✗ Password not found or open network" -ForegroundColor Yellow
    }
}
elseif ($Export) {
    Export-WiFiProfiles -Path $Export
}
elseif ($Import) {
    Import-WiFiProfiles -Path $Import
}
elseif ($Delete) {
    Write-Host ""
    Write-Host "Deleting profile: $Delete" -ForegroundColor Yellow
    netsh wlan delete profile name="$Delete"
    Write-Host "✓ Profile deleted" -ForegroundColor Green
}
elseif ($Connect) {
    Write-Host ""
    Write-Host "Connecting to: $Connect" -ForegroundColor Cyan
    netsh wlan connect name="$Connect"
}
else {
    Show-WiFiProfiles
}

Write-Host ""

