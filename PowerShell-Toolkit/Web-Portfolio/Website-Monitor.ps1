#Requires -Version 5.1

<#
.SYNOPSIS
    Website health monitor and uptime checker
.DESCRIPTION
    Monitor website availability, response time, and SSL certificate status
.PARAMETER Url
    Website URL to monitor
.PARAMETER Interval
    Check interval in minutes (default: 5)
.PARAMETER Duration
    Monitoring duration in hours (default: continuous)
.PARAMETER CheckSSL
    Check SSL certificate expiry
.PARAMETER AlertEmail
    Email address for alerts (requires SMTP setup)
.EXAMPLE
    .\Website-Monitor.ps1 -Url "https://example.com" -Interval 5
.EXAMPLE
    .\Website-Monitor.ps1 -Url "https://mysite.com" -CheckSSL
.NOTES
    Author: PowerShell Toolkit
    Logs results for historical tracking
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Url,
    [int]$Interval = 5,
    [int]$Duration,
    [switch]$CheckSSL,
    [string]$AlertEmail
)

$logFile = "$PSScriptRoot\website-monitor.log"
$startTime = Get-Date

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
}

function Test-Website {
    param([string]$WebUrl)
    
    try {
        $startCheck = Get-Date
        $response = Invoke-WebRequest -Uri $WebUrl -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        $endCheck = Get-Date
        $responseTime = ($endCheck - $startCheck).TotalMilliseconds
        
        return @{
            Success = $true
            StatusCode = $response.StatusCode
            ResponseTime = [Math]::Round($responseTime, 2)
            Error = $null
        }
    }
    catch {
        return @{
            Success = $false
            StatusCode = $null
            ResponseTime = $null
            Error = $_.Exception.Message
        }
    }
}

function Get-SSLCertInfo {
    param([string]$WebUrl)
    
    try {
        $uri = [System.Uri]$WebUrl
        $request = [System.Net.HttpWebRequest]::Create($uri)
        $request.Timeout = 10000
        $request.AllowAutoRedirect = $false
        $response = $request.GetResponse()
        
        if ($request.ServicePoint.Certificate) {
            $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]$request.ServicePoint.Certificate
            $daysUntilExpiry = ($cert.NotAfter - (Get-Date)).Days
            
            $response.Close()
            
            return @{
                Issuer = $cert.Issuer
                Subject = $cert.Subject
                ExpiryDate = $cert.NotAfter
                DaysUntilExpiry = $daysUntilExpiry
                IsValid = $daysUntilExpiry -gt 0
            }
        }
    }
    catch {
        return $null
    }
    
    return $null
}

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Website Health Monitor" -ForegroundColor Cyan -NoNewline
Write-Host "                     ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Monitoring: " -NoNewline
Write-Host $Url -ForegroundColor Green
Write-Host "Interval: " -NoNewline
Write-Host "$Interval minutes" -ForegroundColor Yellow
Write-Host "Started: " -NoNewline
Write-Host (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -ForegroundColor Gray
Write-Host ""

# SSL Check if requested
if ($CheckSSL) {
    Write-Host "Checking SSL certificate..." -ForegroundColor Cyan
    $sslInfo = Get-SSLCertInfo -WebUrl $Url
    
    if ($sslInfo) {
        Write-Host "Subject: " -NoNewline
        Write-Host $sslInfo.Subject -ForegroundColor White
        Write-Host "Expiry: " -NoNewline
        $expiryColor = if ($sslInfo.DaysUntilExpiry -lt 30) { "Red" } elseif ($sslInfo.DaysUntilExpiry -lt 60) { "Yellow" } else { "Green" }
        Write-Host "$($sslInfo.ExpiryDate) ($($sslInfo.DaysUntilExpiry) days)" -ForegroundColor $expiryColor
        
        if ($sslInfo.DaysUntilExpiry -lt 30) {
            Write-Host "⚠ SSL certificate expires soon!" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Monitoring loop
$checkCount = 0
$successCount = 0
$failCount = 0
$totalResponseTime = 0

try {
    while ($true) {
        $checkCount++
        
        Write-Host "[Check #$checkCount] " -NoNewline -ForegroundColor Gray
        Write-Host (Get-Date -Format "HH:mm:ss") -NoNewline -ForegroundColor Gray
        Write-Host " - " -NoNewline
        
        $result = Test-Website -WebUrl $Url
        
        if ($result.Success) {
            $successCount++
            $totalResponseTime += $result.ResponseTime
            
            Write-Host "✓ UP" -NoNewline -ForegroundColor Green
            Write-Host " [$($result.StatusCode)] " -NoNewline -ForegroundColor Gray
            Write-Host "$($result.ResponseTime)ms" -ForegroundColor Cyan
            
            Write-Log "Website UP - Status: $($result.StatusCode), Response: $($result.ResponseTime)ms" "SUCCESS"
        }
        else {
            $failCount++
            
            Write-Host "✗ DOWN" -NoNewline -ForegroundColor Red
            Write-Host " - $($result.Error)" -ForegroundColor Red
            
            Write-Log "Website DOWN - Error: $($result.Error)" "ERROR"
            
            # Send alert if email configured
            if ($AlertEmail) {
                Write-Host "  → Alert would be sent to: $AlertEmail" -ForegroundColor Yellow
            }
        }
        
        # Show statistics every 10 checks
        if ($checkCount % 10 -eq 0) {
            $uptime = [Math]::Round(($successCount / $checkCount) * 100, 2)
            $avgResponse = if ($successCount -gt 0) { [Math]::Round($totalResponseTime / $successCount, 2) } else { 0 }
            
            Write-Host ""
            Write-Host "Statistics: " -NoNewline -ForegroundColor Cyan
            Write-Host "Uptime: $uptime% | " -NoNewline -ForegroundColor White
            Write-Host "Avg Response: ${avgResponse}ms | " -NoNewline -ForegroundColor White
            Write-Host "Success: $successCount | " -NoNewline -ForegroundColor Green
            Write-Host "Failed: $failCount" -ForegroundColor Red
            Write-Host ""
        }
        
        # Check duration limit
        if ($Duration) {
            $elapsed = ((Get-Date) - $startTime).TotalHours
            if ($elapsed -ge $Duration) {
                Write-Host "`nMonitoring duration reached" -ForegroundColor Yellow
                break
            }
        }
        
        # Wait for next check
        Start-Sleep -Seconds ($Interval * 60)
    }
}
catch {
    Write-Host "`n✓ Monitoring stopped" -ForegroundColor Yellow
}

# Final summary
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║         Final Summary" -ForegroundColor Green -NoNewline
Write-Host "                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

$uptime = [Math]::Round(($successCount / $checkCount) * 100, 2)
$avgResponse = if ($successCount -gt 0) { [Math]::Round($totalResponseTime / $successCount, 2) } else { 0 }
$totalTime = ((Get-Date) - $startTime).TotalMinutes

Write-Host "Total checks: $checkCount" -ForegroundColor White
Write-Host "Successful: " -NoNewline
Write-Host "$successCount" -ForegroundColor Green
Write-Host "Failed: " -NoNewline
Write-Host "$failCount" -ForegroundColor Red
Write-Host "Uptime: " -NoNewline
$uptimeColor = if ($uptime -ge 99) { "Green" } elseif ($uptime -ge 95) { "Yellow" } else { "Red" }
Write-Host "$uptime%" -ForegroundColor $uptimeColor
Write-Host "Average response: " -NoNewline
Write-Host "${avgResponse}ms" -ForegroundColor Cyan
Write-Host "Duration: " -NoNewline
Write-Host "$([Math]::Round($totalTime, 2)) minutes" -ForegroundColor Gray
Write-Host "`nLog file: $logFile" -ForegroundColor Gray
Write-Host ""

