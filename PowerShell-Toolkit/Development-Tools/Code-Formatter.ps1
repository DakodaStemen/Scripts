#Requires -Version 5.1

<#
.SYNOPSIS
    Code formatter and beautifier
.DESCRIPTION
    Format and beautify code files (PowerShell, JSON, XML)
.PARAMETER Path
    Path to file or directory
.PARAMETER Type
    File type: PowerShell, JSON, XML, All
.PARAMETER Recursive
    Process subdirectories
.PARAMETER Backup
    Create backup before formatting
.EXAMPLE
    .\Code-Formatter.ps1 -Path "script.ps1" -Type PowerShell
.EXAMPLE
    .\Code-Formatter.ps1 -Path "C:\Project" -Type All -Recursive -Backup
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    [ValidateSet("PowerShell", "JSON", "XML", "All")]
    [string]$Type = "All",
    [switch]$Recursive,
    [switch]$Backup
)

function Format-PowerShellCode {
    param([string]$FilePath)
    
    try {
        $content = Get-Content -Path $FilePath -Raw
        
        # Basic formatting rules
        $formatted = $content
        $formatted = $formatted -replace '\r\n', "`n"  # Normalize line endings
        $formatted = $formatted -replace '  +', ' '     # Remove multiple spaces
        $formatted = $formatted -replace ' \n', "`n"    # Remove trailing spaces
        
        Set-Content -Path $FilePath -Value $formatted -NoNewline
        return $true
    }
    catch {
        return $false
    }
}

function Format-JsonFile {
    param([string]$FilePath)
    
    try {
        $json = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        $formatted = $json | ConvertTo-Json -Depth 100
        Set-Content -Path $FilePath -Value $formatted -Encoding UTF8
        return $true
    }
    catch {
        return $false
    }
}

function Format-XmlFile {
    param([string]$FilePath)
    
    try {
        $xml = New-Object System.Xml.XmlDocument
        $xml.Load($FilePath)
        
        $settings = New-Object System.Xml.XmlWriterSettings
        $settings.Indent = $true
        $settings.IndentChars = "  "
        $settings.NewLineChars = "`r`n"
        
        $writer = [System.Xml.XmlWriter]::Create($FilePath, $settings)
        $xml.Save($writer)
        $writer.Close()
        
        return $true
    }
    catch {
        return $false
    }
}

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Code Formatter" -ForegroundColor Cyan -NoNewline
Write-Host "                           ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$files = @()

if (Test-Path -Path $Path -PathType Leaf) {
    $files = @(Get-Item $Path)
}
else {
    $filter = switch ($Type) {
        "PowerShell" { "*.ps1" }
        "JSON" { "*.json" }
        "XML" { "*.xml" }
        "All" { "*.*" }
    }
    
    $files = if ($Recursive) {
        Get-ChildItem -Path $Path -Filter $filter -File -Recurse
    } else {
        Get-ChildItem -Path $Path -Filter $filter -File
    }
    
    # Filter by extension if "All"
    if ($Type -eq "All") {
        $files = $files | Where-Object { $_.Extension -in @('.ps1', '.json', '.xml') }
    }
}

Write-Host "Found $($files.Count) file(s) to format" -ForegroundColor Cyan
Write-Host ""

$formatted = 0
foreach ($file in $files) {
    Write-Host "$($file.Name) " -NoNewline -ForegroundColor White
    
    if ($Backup) {
        $backupPath = "$($file.FullName).bak"
        Copy-Item -Path $file.FullName -Destination $backupPath
    }
    
    $success = $false
    switch ($file.Extension) {
        ".ps1" { $success = Format-PowerShellCode -FilePath $file.FullName }
        ".json" { $success = Format-JsonFile -FilePath $file.FullName }
        ".xml" { $success = Format-XmlFile -FilePath $file.FullName }
    }
    
    if ($success) {
        Write-Host "✓" -ForegroundColor Green
        $formatted++
    }
    else {
        Write-Host "✗" -ForegroundColor Red
    }
}

Write-Host "`n✓ Formatted $formatted file(s)" -ForegroundColor Green
Write-Host ""

