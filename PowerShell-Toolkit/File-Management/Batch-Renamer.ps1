#Requires -Version 5.1

<#
.SYNOPSIS
    Powerful batch file renaming with patterns
.DESCRIPTION
    Rename multiple files using patterns, find/replace, numbering, and more
.PARAMETER Path
    Directory containing files to rename
.PARAMETER Pattern
    New name pattern (use {n} for number, {name} for original name)
.PARAMETER Find
    Text to find in filenames
.PARAMETER Replace
    Replacement text
.PARAMETER DryRun
    Preview changes without renaming
.EXAMPLE
    .\Batch-Renamer.ps1 -Path "C:\Photos" -Pattern "Vacation_{n:000}" -DryRun
.EXAMPLE
    .\Batch-Renamer.ps1 -Path "C:\Files" -Find "old" -Replace "new"
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [string]$Pattern,
    [string]$Find,
    [string]$Replace,
    [switch]$DryRun
)

Write-Host "Batch File Renamer" -ForegroundColor Cyan
Write-Host "Path: $Path" -ForegroundColor Gray

if (-not (Test-Path $Path)) {
    Write-Host "Error: Path not found" -ForegroundColor Red
    exit 1
}

$files = Get-ChildItem -Path $Path -File
Write-Host "Found: $($files.Count) files`n" -ForegroundColor Green

if ($Pattern) {
    $counter = 1
    foreach ($file in $files) {
        $newName = $Pattern -replace '\{n:?(\d*)\}', {
            param($match)
            if ($match.Groups[1].Value) {
                $counter.ToString($match.Groups[1].Value)
            } else {
                $counter
            }
        }
        $newName = $newName -replace '\{name\}', [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
        $newName += $file.Extension
        
        Write-Host "$($file.Name) → $newName" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })
        
        if (-not $DryRun) {
            Rename-Item -Path $file.FullName -NewName $newName
        }
        $counter++
    }
} elseif ($Find -and $Replace) {
    foreach ($file in $files) {
        $newName = $file.Name -replace $Find, $Replace
        if ($newName -ne $file.Name) {
            Write-Host "$($file.Name) → $newName" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })
            if (-not $DryRun) {
                Rename-Item -Path $file.FullName -NewName $newName
            }
        }
    }
}

Write-Host "`n$(if ($DryRun) { 'Preview complete (use without -DryRun to apply)' } else { '✓ Renaming complete!' })" -ForegroundColor $(if ($DryRun) { "Yellow" } else { "Green" })

