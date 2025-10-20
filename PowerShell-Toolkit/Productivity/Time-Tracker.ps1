#Requires -Version 5.1

<#
.SYNOPSIS
    Simple time tracking for projects and tasks
.DESCRIPTION
    Track time spent on projects with start/stop functionality and reporting
.PARAMETER Start
    Start tracking time for a project
.PARAMETER Stop
    Stop current time tracking
.PARAMETER Status
    Show current tracking status
.PARAMETER Report
    Generate time tracking report
.PARAMETER Export
    Export time log to CSV
.EXAMPLE
    .\Time-Tracker.ps1 -Start "Project Alpha"
.EXAMPLE
    .\Time-Tracker.ps1 -Stop
.EXAMPLE
    .\Time-Tracker.ps1 -Report
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [string]$Start,
    [switch]$Stop,
    [switch]$Status,
    [switch]$Report,
    [switch]$Export
)

$timeLogFile = "$PSScriptRoot\time-tracking.json"
$currentTrackingFile = "$PSScriptRoot\current-tracking.json"

function Get-TimeLog {
    if (Test-Path $timeLogFile) {
        return Get-Content $timeLogFile | ConvertFrom-Json
    }
    return @()
}

function Save-TimeLog {
    param($Log)
    $Log | ConvertTo-Json | Out-File -FilePath $timeLogFile -Encoding UTF8
}

function Get-CurrentTracking {
    if (Test-Path $currentTrackingFile) {
        return Get-Content $currentTrackingFile | ConvertFrom-Json
    }
    return $null
}

function Save-CurrentTracking {
    param($Tracking)
    if ($Tracking) {
        $Tracking | ConvertTo-Json | Out-File -FilePath $currentTrackingFile -Encoding UTF8
    }
    else {
        Remove-Item $currentTrackingFile -ErrorAction SilentlyContinue
    }
}

function Format-Duration {
    param([TimeSpan]$Duration)
    
    if ($Duration.TotalHours -ge 1) {
        return "$([Math]::Floor($Duration.TotalHours))h $($Duration.Minutes)m"
    }
    else {
        return "$($Duration.Minutes)m $($Duration.Seconds)s"
    }
}

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Time Tracker" -ForegroundColor Cyan -NoNewline
Write-Host "                             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($Start) {
    $current = Get-CurrentTracking
    
    if ($current) {
        Write-Host "⚠ Already tracking: $($current.Project)" -ForegroundColor Yellow
        Write-Host "Stop current tracking before starting new one" -ForegroundColor Gray
    }
    else {
        $tracking = @{
            Project = $Start
            StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        Save-CurrentTracking -Tracking $tracking
        
        Write-Host "✓ Started tracking: " -NoNewline -ForegroundColor Green
        Write-Host $Start -ForegroundColor Cyan
        Write-Host "Started at: $($tracking.StartTime)" -ForegroundColor Gray
    }
}
elseif ($Stop) {
    $current = Get-CurrentTracking
    
    if (-not $current) {
        Write-Host "✗ No active tracking session" -ForegroundColor Red
    }
    else {
        $startTime = [DateTime]::Parse($current.StartTime)
        $endTime = Get-Date
        $duration = $endTime - $startTime
        
        # Add to log
        $log = @(Get-TimeLog)
        $entry = [PSCustomObject]@{
            Project = $current.Project
            StartTime = $current.StartTime
            EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Duration = $duration.TotalMinutes
        }
        $log += $entry
        Save-TimeLog -Log $log
        
        # Clear current tracking
        Save-CurrentTracking -Tracking $null
        
        Write-Host "✓ Stopped tracking: " -NoNewline -ForegroundColor Green
        Write-Host $current.Project -ForegroundColor Cyan
        Write-Host "Duration: " -NoNewline -ForegroundColor Gray
        Write-Host (Format-Duration -Duration $duration) -ForegroundColor Yellow
    }
}
elseif ($Status) {
    $current = Get-CurrentTracking
    
    if (-not $current) {
        Write-Host "No active tracking session" -ForegroundColor Yellow
    }
    else {
        $startTime = [DateTime]::Parse($current.StartTime)
        $elapsed = (Get-Date) - $startTime
        
        Write-Host "Currently tracking:" -ForegroundColor Cyan
        Write-Host "  Project: " -NoNewline
        Write-Host $current.Project -ForegroundColor White
        Write-Host "  Started: " -NoNewline
        Write-Host $current.StartTime -ForegroundColor Gray
        Write-Host "  Elapsed: " -NoNewline
        Write-Host (Format-Duration -Duration $elapsed) -ForegroundColor Yellow
    }
}
elseif ($Report) {
    $log = Get-TimeLog
    
    if ($log.Count -eq 0) {
        Write-Host "No time entries recorded" -ForegroundColor Yellow
    }
    else {
        Write-Host "Time Tracking Report" -ForegroundColor Cyan
        Write-Host ""
        
        # Group by project
        $byProject = $log | Group-Object Project | Sort-Object Name
        
        foreach ($group in $byProject) {
            $totalMinutes = ($group.Group | Measure-Object -Property Duration -Sum).Sum
            $totalHours = [Math]::Round($totalMinutes / 60, 2)
            $entries = $group.Count
            
            Write-Host "$($group.Name)" -ForegroundColor White
            Write-Host "  Total time: " -NoNewline -ForegroundColor Gray
            Write-Host "${totalHours}h" -NoNewline -ForegroundColor Yellow
            Write-Host " ($entries entries)" -ForegroundColor Gray
            Write-Host ""
        }
        
        $grandTotal = ($log | Measure-Object -Property Duration -Sum).Sum / 60
        Write-Host "Grand Total: " -NoNewline
        Write-Host "$([Math]::Round($grandTotal, 2))h" -ForegroundColor Green
    }
}
elseif ($Export) {
    $log = Get-TimeLog
    
    if ($log.Count -eq 0) {
        Write-Host "No time entries to export" -ForegroundColor Yellow
    }
    else {
        $exportPath = "time-tracking_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
        $log | Select-Object Project, StartTime, EndTime, @{Name='Hours';Expression={[Math]::Round($_.Duration / 60, 2)}} | 
               Export-Csv -Path $exportPath -NoTypeInformation
        Write-Host "✓ Exported to: $exportPath" -ForegroundColor Green
    }
}
else {
    # Default: Show status and quick summary
    $current = Get-CurrentTracking
    
    if ($current) {
        $startTime = [DateTime]::Parse($current.StartTime)
        $elapsed = (Get-Date) - $startTime
        
        Write-Host "▶ Currently tracking: " -NoNewline -ForegroundColor Green
        Write-Host $current.Project -ForegroundColor Cyan
        Write-Host "  Elapsed: " -NoNewline -ForegroundColor Gray
        Write-Host (Format-Duration -Duration $elapsed) -ForegroundColor Yellow
    }
    else {
        Write-Host "No active tracking" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "Commands:" -ForegroundColor Cyan
    Write-Host "  -Start `"Project Name`"  Start tracking" -ForegroundColor White
    Write-Host "  -Stop                  Stop tracking" -ForegroundColor White
    Write-Host "  -Status                Show current status" -ForegroundColor White
    Write-Host "  -Report                View time report" -ForegroundColor White
}

Write-Host ""

