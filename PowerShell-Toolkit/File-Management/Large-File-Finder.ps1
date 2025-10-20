#Requires -Version 5.1

<#
.SYNOPSIS
    Find large files consuming disk space
.DESCRIPTION
    Scans directories to identify the largest files, helping to free up disk space
.PARAMETER Path
    Path to scan (default: C:\)
.PARAMETER MinSize
    Minimum file size in MB (default: 100)
.PARAMETER Top
    Number of results to show (default: 20)
.PARAMETER ExportResults
    Export results to CSV
.EXAMPLE
    .\Large-File-Finder.ps1 -Path "C:\Users" -MinSize 500 -Top 10
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [string]$Path = "C:\",
    [int]$MinSize = 100,
    [int]$Top = 20,
    [switch]$ExportResults
)

function Format-FileSize {
    param([long]$Size)
    
    if ($Size -gt 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    } elseif ($Size -gt 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    } else {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
}

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Large File Finder" -ForegroundColor Cyan -NoNewline
Write-Host "                       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Scanning: " -NoNewline
Write-Host $Path -ForegroundColor Green
Write-Host "Min Size: " -NoNewline
Write-Host "${MinSize} MB" -ForegroundColor Yellow
Write-Host ""

Write-Host "Analyzing files..." -ForegroundColor Cyan
$minSizeBytes = $MinSize * 1MB

$largeFiles = Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue |
    Where-Object { $_.Length -ge $minSizeBytes } |
    Sort-Object Length -Descending |
    Select-Object -First $Top |
    ForEach-Object {
        [PSCustomObject]@{
            Name = $_.Name
            Path = $_.FullName
            Size = $_.Length
            SizeFormatted = Format-FileSize -Size $_.Length
            Modified = $_.LastWriteTime
            Extension = $_.Extension
        }
    }

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Results" -ForegroundColor Green -NoNewline
Write-Host "                                ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($largeFiles.Count -eq 0) {
    Write-Host "No files found larger than ${MinSize}MB" -ForegroundColor Yellow
} else {
    Write-Host "Top $($largeFiles.Count) largest files:" -ForegroundColor Cyan
    Write-Host ""
    
    $counter = 1
    foreach ($file in $largeFiles) {
        Write-Host "$counter. " -NoNewline -ForegroundColor Gray
        Write-Host $file.SizeFormatted -NoNewline -ForegroundColor Yellow
        Write-Host " - " -NoNewline -ForegroundColor Gray
        Write-Host $file.Name -ForegroundColor White
        Write-Host "   $($file.Path)" -ForegroundColor Gray
        $counter++
    }
    
    $totalSize = ($largeFiles | Measure-Object -Property Size -Sum).Sum
    Write-Host "`nTotal size: " -NoNewline
    Write-Host (Format-FileSize -Size $totalSize) -ForegroundColor Green
    
    if ($ExportResults) {
        $reportPath = "large-files_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
        $largeFiles | Select-Object Name, Path, SizeFormatted, Modified, Extension | Export-Csv -Path $reportPath -NoTypeInformation
        Write-Host "`n✓ Results exported to: $reportPath" -ForegroundColor Green
    }
}

Write-Host ""

