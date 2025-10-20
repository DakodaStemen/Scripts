#Requires -Version 5.1

<#
.SYNOPSIS
    Automatically organize and rename screenshots
.DESCRIPTION
    Monitors and organizes screenshots with intelligent naming and folder structure
.PARAMETER SourcePath
    Path containing screenshots (default: user's Pictures folder)
.PARAMETER Auto
    Run automatically in background
.EXAMPLE
    .\Screenshot-Organizer.ps1 -SourcePath "C:\Users\John\Desktop"
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [string]$SourcePath = "$env:USERPROFILE\Pictures",
    [switch]$Auto
)

$screenshotPatterns = @("Screenshot*", "Screen Shot*", "Capture*", "IMG_*")

function Organize-Screenshots {
    $organized = Join-Path $SourcePath "Organized-Screenshots"
    if (-not (Test-Path $organized)) {
        New-Item -ItemType Directory -Path $organized -Force | Out-Null
    }
    
    $screenshots = Get-ChildItem -Path $SourcePath -File | Where-Object {
        $name = $_.Name
        $screenshotPatterns | ForEach-Object { if ($name -like $_) { return $true } }
    }
    
    $count = 0
    foreach ($file in $screenshots) {
        $year = $file.LastWriteTime.Year
        $month = $file.LastWriteTime.ToString("yyyy-MM")
        $dest = Join-Path $organized "$year\$month"
        
        if (-not (Test-Path $dest)) {
            New-Item -ItemType Directory -Path $dest -Force | Out-Null
        }
        
        $newName = "Screenshot_$($file.LastWriteTime.ToString('yyyy-MM-dd_HHmmss'))$($file.Extension)"
        Move-Item -Path $file.FullName -Destination (Join-Path $dest $newName) -Force
        $count++
    }
    
    if ($count -gt 0) {
        Write-Host "✓ Organized $count screenshot(s)" -ForegroundColor Green
    }
}

Write-Host "Screenshot Organizer" -ForegroundColor Cyan
Write-Host "Source: $SourcePath" -ForegroundColor Gray
Organize-Screenshots

