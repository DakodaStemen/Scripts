#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows service manager and monitor
.DESCRIPTION
    View, start, stop, and configure Windows services with ease
.PARAMETER List
    List all services with status
.PARAMETER Status
    Filter by status: Running, Stopped, All (default: All)
.PARAMETER Start
    Start service by name
.PARAMETER Stop
    Stop service by name
.PARAMETER Restart
    Restart service by name
.PARAMETER Search
    Search services by name
.PARAMETER Export
    Export service list to CSV
.EXAMPLE
    .\Service-Manager.ps1 -List -Status Running
.EXAMPLE
    .\Service-Manager.ps1 -Restart "wuauserv"
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator privileges
#>

param(
    [switch]$List,
    [ValidateSet("Running", "Stopped", "All")]
    [string]$Status = "All",
    [string]$Start,
    [string]$Stop,
    [string]$Restart,
    [string]$Search,
    [switch]$Export
)

function Show-Services {
    param([string]$StatusFilter)
    
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║      Windows Service Manager" -ForegroundColor Cyan -NoNewline
    Write-Host "                    ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $services = Get-Service
    
    if ($StatusFilter -ne "All") {
        $services = $services | Where-Object { $_.Status -eq $StatusFilter }
    }
    
    Write-Host "Filter: " -NoNewline
    Write-Host $StatusFilter -ForegroundColor Yellow
    Write-Host "Total: " -NoNewline
    Write-Host $services.Count -ForegroundColor Green
    Write-Host ""
    
    $services | Sort-Object DisplayName | ForEach-Object {
        $statusColor = if ($_.Status -eq "Running") { "Green" } else { "Gray" }
        
        Write-Host $_.DisplayName -NoNewline -ForegroundColor White
        Write-Host " (" -NoNewline -ForegroundColor Gray
        Write-Host $_.Name -NoNewline -ForegroundColor Cyan
        Write-Host ") - " -NoNewline -ForegroundColor Gray
        Write-Host $_.Status -ForegroundColor $statusColor
    }
}

function Start-ServiceByName {
    param([string]$ServiceName)
    
    try {
        Write-Host "Starting service: $ServiceName" -ForegroundColor Cyan
        Start-Service -Name $ServiceName -ErrorAction Stop
        Write-Host "✓ Service started successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-ServiceByName {
    param([string]$ServiceName)
    
    try {
        Write-Host "Stopping service: $ServiceName" -ForegroundColor Yellow
        Stop-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Host "✓ Service stopped successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Restart-ServiceByName {
    param([string]$ServiceName)
    
    try {
        Write-Host "Restarting service: $ServiceName" -ForegroundColor Cyan
        Restart-Service -Name $ServiceName -Force -ErrorAction Stop
        Write-Host "✓ Service restarted successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Service Manager" -ForegroundColor Cyan -NoNewline
Write-Host "                            ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($List) {
    Show-Services -StatusFilter $Status
}
elseif ($Start) {
    Start-ServiceByName -ServiceName $Start
}
elseif ($Stop) {
    Stop-ServiceByName -ServiceName $Stop
}
elseif ($Restart) {
    Restart-ServiceByName -ServiceName $Restart
}
elseif ($Search) {
    Write-Host ""
    $results = Get-Service | Where-Object { $_.Name -like "*$Search*" -or $_.DisplayName -like "*$Search*" }
    
    if ($results.Count -eq 0) {
        Write-Host "No services found matching: $Search" -ForegroundColor Yellow
    }
    else {
        Write-Host "Found $($results.Count) service(s):" -ForegroundColor Green
        Write-Host ""
        $results | ForEach-Object {
            $statusColor = if ($_.Status -eq "Running") { "Green" } else { "Gray" }
            Write-Host $_.DisplayName -NoNewline -ForegroundColor White
            Write-Host " [$($_.Name)] - " -NoNewline -ForegroundColor Cyan
            Write-Host $_.Status -ForegroundColor $statusColor
        }
    }
}
elseif ($Export) {
    $exportPath = "services_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
    Get-Service | Select-Object Name, DisplayName, Status, StartType | Export-Csv -Path $exportPath -NoTypeInformation
    Write-Host "`n✓ Services exported to: $exportPath" -ForegroundColor Green
}
else {
    Show-Services -StatusFilter $Status
}

Write-Host ""

