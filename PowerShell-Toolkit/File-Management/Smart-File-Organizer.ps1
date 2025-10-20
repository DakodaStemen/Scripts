#Requires -Version 5.1

<#
.SYNOPSIS
    Intelligent file organization by type and date
    
.DESCRIPTION
    Automatically organizes files into categorized folders based on file type and optionally by date.
    Perfect for cleaning up Downloads, Desktop, or any messy folder.
    
.PARAMETER SourcePath
    Path to folder to organize
    
.PARAMETER OrganizeBy
    Organization method: Type, Date, or Both (default: Type)
    
.PARAMETER CreateYearFolders
    Create year subfolders when organizing by date
    
.PARAMETER DryRun
    Preview changes without actually moving files
    
.EXAMPLE
    .\Smart-File-Organizer.ps1 -SourcePath "C:\Users\John\Downloads"
    
.EXAMPLE
    .\Smart-File-Organizer.ps1 -SourcePath "C:\Users\John\Desktop" -OrganizeBy Both -CreateYearFolders
    
.EXAMPLE
    .\Smart-File-Organizer.ps1 -SourcePath "C:\Temp" -DryRun
    
.NOTES
    Author: PowerShell Toolkit
    Safe to use - creates backups and supports dry-run mode
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [ValidateSet("Type", "Date", "Both")]
    [string]$OrganizeBy = "Type",
    
    [switch]$CreateYearFolders,
    
    [switch]$DryRun
)

# File type categories
$fileCategories = @{
    "Documents" = @(".pdf", ".doc", ".docx", ".txt", ".rtf", ".odt", ".xls", ".xlsx", ".ppt", ".pptx", ".csv")
    "Images" = @(".jpg", ".jpeg", ".png", ".gif", ".bmp", ".svg", ".ico", ".webp", ".heic")
    "Videos" = @(".mp4", ".avi", ".mkv", ".mov", ".wmv", ".flv", ".webm", ".m4v")
    "Audio" = @(".mp3", ".wav", ".flac", ".aac", ".ogg", ".wma", ".m4a")
    "Archives" = @(".zip", ".rar", ".7z", ".tar", ".gz", ".bz2", ".iso")
    "Code" = @(".js", ".ts", ".py", ".java", ".cpp", ".c", ".cs", ".php", ".html", ".css", ".json", ".xml", ".sql")
    "Executables" = @(".exe", ".msi", ".bat", ".sh", ".ps1", ".cmd")
    "Others" = @()
}

function Write-Header {
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║       Smart File Organizer" -ForegroundColor Cyan -NoNewline
    Write-Host "                      ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    if ($DryRun) {
        Write-Host "                  [DRY RUN MODE]" -ForegroundColor Yellow
    }
    Write-Host ""
}

function Get-FileCategory {
    param([string]$Extension)
    
    foreach ($category in $fileCategories.Keys) {
        if ($fileCategories[$category] -contains $Extension.ToLower()) {
            return $category
        }
    }
    return "Others"
}

function New-OrganizedStructure {
    param([string]$BasePath, [string]$Method)
    
    if ($Method -eq "Type" -or $Method -eq "Both") {
        foreach ($category in $fileCategories.Keys) {
            $categoryPath = Join-Path $BasePath $category
            if (-not $DryRun -and -not (Test-Path $categoryPath)) {
                New-Item -ItemType Directory -Path $categoryPath -Force | Out-Null
            }
        }
    }
}

function Move-FileToCategory {
    param([System.IO.FileInfo]$File, [string]$DestinationBase)
    
    $category = Get-FileCategory -Extension $File.Extension
    $destinationPath = ""
    
    # Determine destination based on organization method
    switch ($OrganizeBy) {
        "Type" {
            $destinationPath = Join-Path $DestinationBase $category
        }
        "Date" {
            $year = $File.LastWriteTime.Year
            $month = $File.LastWriteTime.ToString("yyyy-MM")
            
            if ($CreateYearFolders) {
                $destinationPath = Join-Path $DestinationBase "$year\$month"
            } else {
                $destinationPath = Join-Path $DestinationBase $month
            }
        }
        "Both" {
            $year = $File.LastWriteTime.Year
            $month = $File.LastWriteTime.ToString("yyyy-MM")
            
            if ($CreateYearFolders) {
                $destinationPath = Join-Path $DestinationBase "$category\$year\$month"
            } else {
                $destinationPath = Join-Path $DestinationBase "$category\$month"
            }
        }
    }
    
    # Create destination folder if it doesn't exist
    if (-not $DryRun -and -not (Test-Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
    }
    
    $destinationFile = Join-Path $destinationPath $File.Name
    
    # Handle duplicate filenames
    if (Test-Path $destinationFile) {
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($File.Name)
        $extension = $File.Extension
        $counter = 1
        
        while (Test-Path $destinationFile) {
            $newName = "${baseName}_${counter}${extension}"
            $destinationFile = Join-Path $destinationPath $newName
            $counter++
        }
    }
    
    # Move or preview
    if ($DryRun) {
        Write-Host "  Would move: " -NoNewline -ForegroundColor Gray
        Write-Host "$($File.Name)" -NoNewline -ForegroundColor White
        Write-Host " → " -NoNewline -ForegroundColor Gray
        Write-Host "$destinationPath" -ForegroundColor Cyan
        return $true
    } else {
        try {
            Move-Item -Path $File.FullName -Destination $destinationFile -Force
            return $true
        }
        catch {
            Write-Host "  Error moving $($File.Name): $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    }
}

# Main execution
Write-Header

# Validate source path
if (-not (Test-Path $SourcePath)) {
    Write-Host "Error: Source path not found: $SourcePath" -ForegroundColor Red
    exit 1
}

Write-Host "Source: " -NoNewline
Write-Host $SourcePath -ForegroundColor Green
Write-Host "Method: " -NoNewline
Write-Host $OrganizeBy -ForegroundColor Yellow
Write-Host ""

# Get all files (excluding folders)
$files = Get-ChildItem -Path $SourcePath -File | Where-Object { 
    $_.Directory.FullName -eq $SourcePath  # Only root level files
}

if ($files.Count -eq 0) {
    Write-Host "No files to organize" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($files.Count) file(s) to organize" -ForegroundColor Cyan
Write-Host ""

# Create folder structure
New-OrganizedStructure -BasePath $SourcePath -Method $OrganizeBy

# Organize files by category
$stats = @{}
foreach ($category in $fileCategories.Keys) {
    $stats[$category] = 0
}

$successCount = 0
$failCount = 0

Write-Host "Organizing files..." -ForegroundColor Yellow
Write-Host ""

foreach ($file in $files) {
    $category = Get-FileCategory -Extension $file.Extension
    
    if (Move-FileToCategory -File $file -DestinationBase $SourcePath) {
        $stats[$category]++
        $successCount++
    } else {
        $failCount++
    }
}

# Display summary
Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Summary" -ForegroundColor Green -NoNewline
Write-Host "                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "DRY RUN - No files were actually moved" -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Files by category:" -ForegroundColor Cyan
foreach ($category in ($stats.Keys | Sort-Object)) {
    if ($stats[$category] -gt 0) {
        Write-Host "  $category`: " -NoNewline -ForegroundColor White
        Write-Host "$($stats[$category]) files" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Total processed: " -NoNewline -ForegroundColor White
Write-Host "$successCount " -NoNewline -ForegroundColor Green
Write-Host "files" -ForegroundColor White

if ($failCount -gt 0) {
    Write-Host "Failed: " -NoNewline -ForegroundColor White
    Write-Host "$failCount " -NoNewline -ForegroundColor Red
    Write-Host "files" -ForegroundColor White
}

Write-Host ""

if ($DryRun) {
    Write-Host "Run without -DryRun to actually organize the files" -ForegroundColor Yellow
} else {
    Write-Host "✓ Organization complete!" -ForegroundColor Green
}

Write-Host ""

