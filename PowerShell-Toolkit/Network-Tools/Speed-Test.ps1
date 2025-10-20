#Requires -Version 5.1

<#
.SYNOPSIS
    Internet speed test with logging
    
.DESCRIPTION
    Tests internet download/upload speeds and latency using multiple methods.
    Logs results for tracking performance over time.
    
.PARAMETER LogResults
    Save results to log file
    
.PARAMETER Iterations
    Number of test iterations (default: 1)
    
.PARAMETER TestServer
    Custom test server URL (optional)
    
.EXAMPLE
    .\Speed-Test.ps1
    
.EXAMPLE
    .\Speed-Test.ps1 -LogResults -Iterations 3
    
.NOTES
    Author: PowerShell Toolkit
    Requires: Internet connection
#>

param(
    [switch]$LogResults,
    [int]$Iterations = 1,
    [string]$TestServer
)

$logPath = "$PSScriptRoot\speed-test-log.csv"

function Write-Header {
    Clear-Host
    Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Internet Speed Test" -ForegroundColor Cyan -NoNewline
    Write-Host "                     ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Test-InternetConnection {
    Write-Host "Testing connection..." -ForegroundColor Cyan
    try {
        $ping = Test-Connection -ComputerName "8.8.8.8" -Count 4 -ErrorAction Stop
        $avgLatency = ($ping | Measure-Object -Property ResponseTime -Average).Average
        Write-Host "✓ Connected - Latency: " -NoNewline -ForegroundColor Green
        Write-Host "$([Math]::Round($avgLatency)) ms" -ForegroundColor White
        return $avgLatency
    }
    catch {
        Write-Host "✗ No internet connection" -ForegroundColor Red
        return $null
    }
}

function Test-DownloadSpeed {
    param([string]$Url)
    
    Write-Host "`nTesting download speed..." -ForegroundColor Cyan
    
    # Use a test file (10MB from a fast CDN)
    if (-not $Url) {
        $Url = "http://ipv4.download.thinkbroadband.com/10MB.zip"
    }
    
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $startTime = Get-Date
        
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $tempFile)
        
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalSeconds
        
        $fileSize = (Get-Item $tempFile).Length
        $speedMbps = [Math]::Round((($fileSize * 8) / $duration) / 1MB, 2)
        
        Remove-Item $tempFile -Force
        
        Write-Host "✓ Download speed: " -NoNewline -ForegroundColor Green
        Write-Host "$speedMbps Mbps" -ForegroundColor White
        
        return $speedMbps
    }
    catch {
        Write-Host "✗ Download test failed: $($_.Exception.Message)" -ForegroundColor Red
        return 0
    }
}

function Get-PublicIP {
    try {
        $ip = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing -TimeoutSec 5).Content
        return $ip
    }
    catch {
        return "Unknown"
    }
}

function Get-ISPInfo {
    try {
        $ipInfo = Invoke-RestMethod -Uri "http://ip-api.com/json/" -TimeoutSec 5
        return $ipInfo
    }
    catch {
        return $null
    }
}

function Write-SpeedBar {
    param([double]$Speed, [double]$MaxSpeed = 100)
    
    $percentage = [Math]::Min(($Speed / $MaxSpeed) * 100, 100)
    $barLength = 40
    $filledLength = [Math]::Round(($percentage / 100) * $barLength)
    
    $bar = ""
    for ($i = 0; $i -lt $barLength; $i++) {
        if ($i -lt $filledLength) {
            $bar += "█"
        } else {
            $bar += "░"
        }
    }
    
    $color = if ($Speed -gt 50) { "Green" } elseif ($Speed -gt 20) { "Yellow" } else { "Red" }
    Write-Host $bar -ForegroundColor $color
}

# Main execution
Write-Header

# Get network info
Write-Host "Network Information:" -ForegroundColor Cyan
Write-Host "─────────────────────────────────────────────────" -ForegroundColor Gray

$publicIP = Get-PublicIP
Write-Host "Public IP: " -NoNewline
Write-Host $publicIP -ForegroundColor White

$ispInfo = Get-ISPInfo
if ($ispInfo) {
    Write-Host "ISP: " -NoNewline
    Write-Host $ispInfo.isp -ForegroundColor White
    Write-Host "Location: " -NoNewline
    Write-Host "$($ispInfo.city), $($ispInfo.country)" -ForegroundColor White
}

Write-Host ""

$results = @()

for ($i = 1; $i -le $Iterations; $i++) {
    if ($Iterations -gt 1) {
        Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Yellow
        Write-Host "║  Test Run $i of $Iterations" -ForegroundColor Yellow -NoNewline
        Write-Host (" " * (44 - " Test Run $i of $Iterations".Length)) -NoNewline -ForegroundColor Yellow
        Write-Host "║" -ForegroundColor Yellow
        Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Yellow
        Write-Host ""
    }
    
    # Test latency
    $latency = Test-InternetConnection
    
    if ($null -eq $latency) {
        Write-Host "Cannot proceed without internet connection" -ForegroundColor Red
        exit 1
    }
    
    # Test download
    $downloadSpeed = Test-DownloadSpeed -Url $TestServer
    
    if ($downloadSpeed -gt 0) {
        Write-Host ""
        Write-SpeedBar -Speed $downloadSpeed -MaxSpeed 100
    }
    
    $result = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Latency = [Math]::Round($latency, 2)
        DownloadMbps = $downloadSpeed
        PublicIP = $publicIP
        ISP = if ($ispInfo) { $ispInfo.isp } else { "Unknown" }
    }
    
    $results += $result
    
    if ($i -lt $Iterations) {
        Write-Host "`nWaiting before next test..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        Write-Host ""
    }
}

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Summary" -ForegroundColor Green -NoNewline
Write-Host "                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($results.Count -gt 1) {
    $avgLatency = ($results | Measure-Object -Property Latency -Average).Average
    $avgDownload = ($results | Measure-Object -Property DownloadMbps -Average).Average
    
    Write-Host "Average Results ($Iterations tests):" -ForegroundColor Cyan
    Write-Host "  Latency: " -NoNewline
    Write-Host "$([Math]::Round($avgLatency, 2)) ms" -ForegroundColor White
    Write-Host "  Download: " -NoNewline
    Write-Host "$([Math]::Round($avgDownload, 2)) Mbps" -ForegroundColor White
} else {
    Write-Host "Latency: " -NoNewline
    Write-Host "$($results[0].Latency) ms" -ForegroundColor White
    Write-Host "Download: " -NoNewline
    Write-Host "$($results[0].DownloadMbps) Mbps" -ForegroundColor White
}

# Speed rating
$speed = if ($results.Count -gt 1) { ($results | Measure-Object -Property DownloadMbps -Average).Average } else { $results[0].DownloadMbps }

Write-Host "`nSpeed Rating: " -NoNewline
if ($speed -gt 100) {
    Write-Host "Excellent (>100 Mbps)" -ForegroundColor Green
} elseif ($speed -gt 50) {
    Write-Host "Very Good (50-100 Mbps)" -ForegroundColor Green
} elseif ($speed -gt 25) {
    Write-Host "Good (25-50 Mbps)" -ForegroundColor Yellow
} elseif ($speed -gt 10) {
    Write-Host "Average (10-25 Mbps)" -ForegroundColor Yellow
} else {
    Write-Host "Slow (<10 Mbps)" -ForegroundColor Red
}

# Log results
if ($LogResults) {
    $fileExists = Test-Path $logPath
    
    $results | Export-Csv -Path $logPath -Append -NoTypeInformation
    
    Write-Host "`n✓ Results logged to: $logPath" -ForegroundColor Green
    
    if ($fileExists) {
        $logEntries = Import-Csv $logPath
        Write-Host "Total log entries: $($logEntries.Count)" -ForegroundColor Gray
    }
}

Write-Host ""

