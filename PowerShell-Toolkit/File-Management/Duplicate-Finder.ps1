#Requires -Version 5.1

<#
.SYNOPSIS
    Find and remove duplicate files
    
.DESCRIPTION
    Scans directory for duplicate files based on content hash (MD5).
    Provides interactive mode to review and delete duplicates safely.
    
.PARAMETER Path
    Path to scan for duplicates
    
.PARAMETER Recursive
    Scan subdirectories recursively
    
.PARAMETER AutoDelete
    Automatically delete duplicates (keeps oldest file)
    
.PARAMETER MinSize
    Minimum file size to scan in MB (default: 0)
    
.PARAMETER ExportReport
    Export findings to CSV file
    
.EXAMPLE
    .\Duplicate-Finder.ps1 -Path "C:\Users\John\Pictures" -Recursive
    
.EXAMPLE
    .\Duplicate-Finder.ps1 -Path "D:\Downloads" -MinSize 1 -ExportReport
    
.NOTES
    Author: PowerShell Toolkit
    Uses MD5 hash for content comparison
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [switch]$Recursive,
    
    [switch]$AutoDelete,
    
    [int]$MinSize = 0,
    
    [switch]$ExportReport
)

function Write-Header {
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          Duplicate File Finder" -ForegroundColor Cyan -NoNewline
    Write-Host "                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-FileHash256 {
    param([string]$FilePath)
    try {
        $hash = Get-FileHash -Path $FilePath -Algorithm MD5 -ErrorAction Stop
        return $hash.Hash
    }
    catch {
        return $null
    }
}

function Format-FileSize {
    param([long]$Size)
    
    if ($Size -gt 1GB) {
        return "{0:N2} GB" -f ($Size / 1GB)
    }
    elseif ($Size -gt 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -gt 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "$Size bytes"
    }
}

# Main execution
Write-Header

if (-not (Test-Path $Path)) {
    Write-Host "Error: Path not found: $Path" -ForegroundColor Red
    exit 1
}

Write-Host "Scanning: " -NoNewline
Write-Host $Path -ForegroundColor Green
Write-Host "Mode: " -NoNewline
Write-Host $(if ($Recursive) { "Recursive" } else { "Current folder only" }) -ForegroundColor Yellow
if ($MinSize -gt 0) {
    Write-Host "Min size: " -NoNewline
    Write-Host "${MinSize} MB" -ForegroundColor Yellow
}
Write-Host ""

# Get files
Write-Host "Collecting files..." -ForegroundColor Cyan
$files = if ($Recursive) {
    Get-ChildItem -Path $Path -File -Recurse -ErrorAction SilentlyContinue
} else {
    Get-ChildItem -Path $Path -File -ErrorAction SilentlyContinue
}

# Filter by minimum size
if ($MinSize -gt 0) {
    $minSizeBytes = $MinSize * 1MB
    $files = $files | Where-Object { $_.Length -ge $minSizeBytes }
}

Write-Host "Found $($files.Count) files to analyze" -ForegroundColor Green
Write-Host ""

if ($files.Count -eq 0) {
    Write-Host "No files to scan" -ForegroundColor Yellow
    exit 0
}

# Calculate hashes
Write-Host "Calculating file hashes..." -ForegroundColor Cyan
$hashTable = @{}
$processed = 0

foreach ($file in $files) {
    $processed++
    $percent = [Math]::Round(($processed / $files.Count) * 100)
    Write-Progress -Activity "Hashing files" -Status "$percent% Complete" -PercentComplete $percent
    
    $hash = Get-FileHash256 -FilePath $file.FullName
    
    if ($hash) {
        if (-not $hashTable.ContainsKey($hash)) {
            $hashTable[$hash] = @()
        }
        $hashTable[$hash] += $file
    }
}

Write-Progress -Activity "Hashing files" -Completed

# Find duplicates
$duplicateGroups = $hashTable.Values | Where-Object { $_.Count -gt 1 }

if ($duplicateGroups.Count -eq 0) {
    Write-Host "✓ No duplicate files found!" -ForegroundColor Green
    exit 0
}

# Display duplicates
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║       Found Duplicate Files!" -ForegroundColor Yellow -NoNewline
Write-Host "                      ║" -ForegroundColor Yellow
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""

$totalDuplicateFiles = 0
$totalWastedSpace = 0
$report = @()

foreach ($group in $duplicateGroups) {
    $original = $group | Sort-Object LastWriteTime | Select-Object -First 1
    $duplicates = $group | Where-Object { $_.FullName -ne $original.FullName }
    
    $totalDuplicateFiles += $duplicates.Count
    $wastedSpace = $duplicates | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
    $totalWastedSpace += $wastedSpace
    
    Write-Host "Duplicate set #$($duplicateGroups.IndexOf($group) + 1)" -ForegroundColor Cyan
    Write-Host "  Original: " -NoNewline -ForegroundColor Green
    Write-Host $original.FullName -ForegroundColor White
    Write-Host "  Size: " -NoNewline -ForegroundColor Gray
    Write-Host (Format-FileSize -Size $original.Length) -ForegroundColor White
    Write-Host "  Modified: " -NoNewline -ForegroundColor Gray
    Write-Host $original.LastWriteTime -ForegroundColor White
    Write-Host ""
    
    foreach ($dup in $duplicates) {
        Write-Host "  Duplicate: " -NoNewline -ForegroundColor Red
        Write-Host $dup.FullName -ForegroundColor White
        Write-Host "  Modified: " -NoNewline -ForegroundColor Gray
        Write-Host $dup.LastWriteTime -ForegroundColor White
        
        $report += [PSCustomObject]@{
            Original = $original.FullName
            Duplicate = $dup.FullName
            Size = $dup.Length
            ModifiedDate = $dup.LastWriteTime
        }
    }
    Write-Host ""
}

# Summary
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Summary" -ForegroundColor Green -NoNewline
Write-Host "                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "Duplicate groups: " -NoNewline
Write-Host $duplicateGroups.Count -ForegroundColor Yellow
Write-Host "Total duplicate files: " -NoNewline
Write-Host $totalDuplicateFiles -ForegroundColor Red
Write-Host "Wasted space: " -NoNewline
Write-Host (Format-FileSize -Size $totalWastedSpace) -ForegroundColor Red
Write-Host ""

# Export report if requested
if ($ExportReport) {
    $reportPath = Join-Path $Path "duplicate-report_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
    $report | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "Report exported to: $reportPath" -ForegroundColor Green
    Write-Host ""
}

# Delete duplicates if requested
if ($AutoDelete) {
    Write-Host "Deleting duplicate files..." -ForegroundColor Yellow
    $deletedCount = 0
    $freedSpace = 0
    
    foreach ($group in $duplicateGroups) {
        $original = $group | Sort-Object LastWriteTime | Select-Object -First 1
        $duplicates = $group | Where-Object { $_.FullName -ne $original.FullName }
        
        foreach ($dup in $duplicates) {
            try {
                $freedSpace += $dup.Length
                Remove-Item -Path $dup.FullName -Force
                $deletedCount++
                Write-Host "  Deleted: $($dup.Name)" -ForegroundColor Green
            }
            catch {
                Write-Host "  Error deleting: $($dup.Name)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "✓ Deleted $deletedCount duplicate file(s)" -ForegroundColor Green
    Write-Host "✓ Freed $(Format-FileSize -Size $freedSpace)" -ForegroundColor Green
}
else {
    Write-Host "Run with -AutoDelete to remove duplicates automatically" -ForegroundColor Yellow
    Write-Host "(Original files will be kept based on earliest modification date)" -ForegroundColor Gray
}

Write-Host ""

