#Requires -Version 5.1

<#
.SYNOPSIS
    Interactive process manager with kill capability
.DESCRIPTION
    View, filter, and kill processes with an easy-to-use interface
.PARAMETER FilterName
    Filter processes by name
.PARAMETER SortBy
    Sort by: CPU, Memory, Name (default: Memory)
.PARAMETER Top
    Show top N processes (default: 20)
.PARAMETER KillProcess
    Process name or ID to kill
.EXAMPLE
    .\Process-Manager.ps1 -Top 10 -SortBy CPU
.EXAMPLE
    .\Process-Manager.ps1 -FilterName "chrome" -KillProcess 1234
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator for some operations
#>

param(
    [string]$FilterName,
    [ValidateSet("CPU", "Memory", "Name")]
    [string]$SortBy = "Memory",
    [int]$Top = 20,
    [string]$KillProcess
)

function Format-Memory {
    param([long]$Bytes)
    if ($Bytes -gt 1GB) {
        return "{0:N2} GB" -f ($Bytes / 1GB)
    } else {
        return "{0:N0} MB" -f ($Bytes / 1MB)
    }
}

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Process Manager" -ForegroundColor Cyan -NoNewline
Write-Host "                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Kill process if specified
if ($KillProcess) {
    try {
        if ($KillProcess -match '^\d+$') {
            $process = Get-Process -Id $KillProcess -ErrorAction Stop
        } else {
            $process = Get-Process -Name $KillProcess -ErrorAction Stop | Select-Object -First 1
        }
        
        Write-Host "Killing process: " -NoNewline
        Write-Host "$($process.Name) (PID: $($process.Id))" -ForegroundColor Yellow
        Stop-Process -Id $process.Id -Force
        Write-Host "✓ Process terminated" -ForegroundColor Green
    } catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host ""
    exit
}

# Get processes
$processes = Get-Process | Where-Object {
    if ($FilterName) {
        $_.Name -like "*$FilterName*"
    } else {
        $true
    }
}

# Sort processes
switch ($SortBy) {
    "CPU" { $processes = $processes | Sort-Object CPU -Descending }
    "Memory" { $processes = $processes | Sort-Object WorkingSet -Descending }
    "Name" { $processes = $processes | Sort-Object Name }
}

$processes = $processes | Select-Object -First $Top

# Display
Write-Host "Showing top $Top processes (sorted by $SortBy)" -ForegroundColor Cyan
if ($FilterName) {
    Write-Host "Filter: " -NoNewline
    Write-Host $FilterName -ForegroundColor Yellow
}
Write-Host ""

$processInfo = $processes | ForEach-Object {
    [PSCustomObject]@{
        PID = $_.Id
        Name = $_.Name
        'CPU(s)' = [Math]::Round($_.CPU, 1)
        Memory = Format-Memory -Bytes $_.WorkingSet
        Threads = $_.Threads.Count
    }
}

$processInfo | Format-Table -AutoSize

# System summary
$totalMemory = (Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB
$freeMemory = (Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB
$usedMemory = $totalMemory - $freeMemory

Write-Host "System Memory: " -NoNewline
Write-Host "$([Math]::Round($usedMemory, 2)) GB / $([Math]::Round($totalMemory, 2)) GB" -ForegroundColor Yellow
Write-Host "Total Processes: " -NoNewline
Write-Host (Get-Process).Count -ForegroundColor Green

Write-Host "`nTo kill a process: .\Process-Manager.ps1 -KillProcess <PID or Name>" -ForegroundColor Gray
Write-Host ""

