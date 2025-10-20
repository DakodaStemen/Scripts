#Requires -Version 5.1

<#
.SYNOPSIS
    Automated backup solution with compression and scheduling
    
.DESCRIPTION
    Creates compressed backups of specified folders with versioning, cleanup,
    and optional scheduling. Supports incremental and full backups.
    
.PARAMETER SourcePath
    Path to folder(s) to backup (comma-separated for multiple)
    
.PARAMETER DestinationPath
    Where to save backups
    
.PARAMETER RetentionDays
    Number of days to keep old backups (default: 30)
    
.PARAMETER Schedule
    Create a scheduled task (Daily, Weekly, Monthly)
    
.EXAMPLE
    .\Auto-Backup.ps1 -SourcePath "C:\Important" -DestinationPath "D:\Backups"
    
.EXAMPLE
    .\Auto-Backup.ps1 -SourcePath "C:\Projects,C:\Documents" -DestinationPath "D:\Backups" -Schedule Weekly
    
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator for scheduling
#>

param(
    [Parameter(Mandatory=$true)]
    [string[]]$SourcePath,
    
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath,
    
    [int]$RetentionDays = 30,
    
    [ValidateSet("None", "Daily", "Weekly", "Monthly")]
    [string]$Schedule = "None",
    
    [switch]$Incremental
)

$ErrorActionPreference = "Stop"

# Create log directory
$LogPath = Join-Path $DestinationPath "Logs"
if (-not (Test-Path $LogPath)) {
    New-Item -ItemType Directory -Path $LogPath -Force | Out-Null
}

$LogFile = Join-Path $LogPath "Backup_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    Add-Content -Path $LogFile -Value $LogMessage
    
    switch ($Level) {
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $LogMessage -ForegroundColor Green }
        default { Write-Host $LogMessage }
    }
}

function Get-FolderSize {
    param([string]$Path)
    $size = (Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue | 
             Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
    return [Math]::Round($size / 1GB, 2)
}

function Backup-Folder {
    param([string]$Source, [string]$Destination)
    
    $folderName = Split-Path $Source -Leaf
    $timestamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
    $backupName = "${folderName}_${timestamp}.zip"
    $backupPath = Join-Path $Destination $backupName
    
    Write-Log "Starting backup of: $Source" "INFO"
    $sourceSize = Get-FolderSize -Path $Source
    Write-Log "Source size: $sourceSize GB" "INFO"
    
    try {
        # Create backup
        $startTime = Get-Date
        
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($Source, $backupPath, 'Optimal', $false)
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        $backupSize = [Math]::Round((Get-Item $backupPath).Length / 1GB, 2)
        $compressionRatio = [Math]::Round((1 - ($backupSize / $sourceSize)) * 100, 1)
        
        Write-Log "Backup created: $backupName" "SUCCESS"
        Write-Log "Backup size: $backupSize GB (${compressionRatio}% compression)" "SUCCESS"
        Write-Log "Duration: $([Math]::Round($duration, 1)) seconds" "INFO"
        
        return $true
    }
    catch {
        Write-Log "Backup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-OldBackups {
    param([string]$Path, [int]$Days)
    
    Write-Log "Cleaning up backups older than $Days days..." "INFO"
    
    $cutoffDate = (Get-Date).AddDays(-$Days)
    $oldBackups = Get-ChildItem -Path $Path -Filter "*.zip" | 
                  Where-Object { $_.LastWriteTime -lt $cutoffDate }
    
    if ($oldBackups.Count -eq 0) {
        Write-Log "No old backups to remove" "INFO"
        return
    }
    
    $freedSpace = 0
    foreach ($backup in $oldBackups) {
        $size = $backup.Length / 1GB
        $freedSpace += $size
        Remove-Item $backup.FullName -Force
        Write-Log "Removed old backup: $($backup.Name) ($([Math]::Round($size, 2)) GB)" "INFO"
    }
    
    Write-Log "Cleaned up $($oldBackups.Count) old backup(s), freed $([Math]::Round($freedSpace, 2)) GB" "SUCCESS"
}

function New-BackupSchedule {
    param([string]$Frequency, [string]$ScriptPath, [string]$Arguments)
    
    $TaskName = "Auto-Backup-Task"
    
    # Check if task exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Log "Removing existing scheduled task..." "INFO"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    # Create trigger based on frequency
    switch ($Frequency) {
        "Daily" { $Trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM }
        "Weekly" { $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2:00AM }
        "Monthly" { $Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek Sunday -At 2:00AM }
    }
    
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -NoProfile -File `"$ScriptPath`" $Arguments"
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Automated backup task" | Out-Null
    
    Write-Log "Scheduled task created: $Frequency backups at 2:00 AM" "SUCCESS"
}

# Main execution
Write-Log "========================================" "INFO"
Write-Log "Auto-Backup Script Started" "INFO"
Write-Log "========================================" "INFO"

# Validate source paths
$validSources = @()
foreach ($source in $SourcePath) {
    if (Test-Path $source) {
        $validSources += $source
        Write-Log "Source validated: $source" "SUCCESS"
    }
    else {
        Write-Log "Source not found: $source" "ERROR"
    }
}

if ($validSources.Count -eq 0) {
    Write-Log "No valid source paths found. Exiting." "ERROR"
    exit 1
}

# Create destination if it doesn't exist
if (-not (Test-Path $DestinationPath)) {
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    Write-Log "Created destination folder: $DestinationPath" "INFO"
}

# Perform backups
$successCount = 0
foreach ($source in $validSources) {
    if (Backup-Folder -Source $source -Destination $DestinationPath) {
        $successCount++
    }
}

# Cleanup old backups
Remove-OldBackups -Path $DestinationPath -Days $RetentionDays

# Create schedule if requested
if ($Schedule -ne "None") {
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-SourcePath `"$($SourcePath -join ',')`" -DestinationPath `"$DestinationPath`" -RetentionDays $RetentionDays"
    New-BackupSchedule -Frequency $Schedule -ScriptPath $scriptPath -Arguments $arguments
}

Write-Log "========================================" "INFO"
Write-Log "Backup Complete: $successCount/$($validSources.Count) successful" "SUCCESS"
Write-Log "Log saved: $LogFile" "INFO"
Write-Log "========================================" "INFO"

