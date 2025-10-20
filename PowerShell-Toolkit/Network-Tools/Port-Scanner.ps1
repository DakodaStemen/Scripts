#Requires -Version 5.1

<#
.SYNOPSIS
    Network port scanner with service detection
.DESCRIPTION
    Scans specified ports on target hosts to identify open ports and running services
.PARAMETER Target
    Target IP address or hostname (default: localhost)
.PARAMETER Ports
    Ports to scan (comma-separated or range like "1-1000")
.PARAMETER CommonPorts
    Scan common ports only (faster)
.PARAMETER Timeout
    Connection timeout in milliseconds (default: 1000)
.EXAMPLE
    .\Port-Scanner.ps1 -Target 192.168.1.1 -CommonPorts
.EXAMPLE
    .\Port-Scanner.ps1 -Target google.com -Ports "80,443,8080"
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [string]$Target = "localhost",
    [string]$Ports = "1-1000",
    [switch]$CommonPorts,
    [int]$Timeout = 1000
)

$commonPortList = @{
    20 = "FTP Data"
    21 = "FTP Control"
    22 = "SSH"
    23 = "Telnet"
    25 = "SMTP"
    53 = "DNS"
    80 = "HTTP"
    110 = "POP3"
    143 = "IMAP"
    443 = "HTTPS"
    445 = "SMB"
    3306 = "MySQL"
    3389 = "RDP"
    5432 = "PostgreSQL"
    5900 = "VNC"
    8080 = "HTTP-Alt"
    8443 = "HTTPS-Alt"
}

function Write-Banner {
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║          Network Port Scanner" -ForegroundColor Cyan -NoNewline
    Write-Host "                   ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Get-PortList {
    if ($CommonPorts) {
        return $commonPortList.Keys | Sort-Object
    }
    
    $portArray = @()
    $portStrings = $Ports -split ','
    
    foreach ($portStr in $portStrings) {
        if ($portStr -match '(\d+)-(\d+)') {
            $start = [int]$matches[1]
            $end = [int]$matches[2]
            $portArray += $start..$end
        } else {
            $portArray += [int]$portStr
        }
    }
    
    return $portArray | Sort-Object -Unique
}

function Test-Port {
    param([string]$Host, [int]$Port, [int]$Timeout)
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($Host, $Port, $null, $null)
        $wait = $asyncResult.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($wait) {
            try {
                $tcpClient.EndConnect($asyncResult)
                $tcpClient.Close()
                return $true
            } catch {
                return $false
            }
        } else {
            return $false
        }
    } catch {
        return $false
    } finally {
        if ($tcpClient) {
            $tcpClient.Close()
        }
    }
}

Write-Banner

Write-Host "Target: " -NoNewline
Write-Host $Target -ForegroundColor Green

# Resolve hostname
try {
    $resolvedIP = [System.Net.Dns]::GetHostAddresses($Target) | Select-Object -First 1
    Write-Host "IP Address: " -NoNewline
    Write-Host $resolvedIP.IPAddressToString -ForegroundColor White
} catch {
    Write-Host "Error: Could not resolve hostname" -ForegroundColor Red
    exit 1
}

$portList = Get-PortList
Write-Host "Scanning: " -NoNewline
Write-Host "$($portList.Count) ports" -ForegroundColor Yellow
Write-Host "Timeout: " -NoNewline
Write-Host "${Timeout}ms" -ForegroundColor Gray
Write-Host ""

Write-Host "Scanning in progress..." -ForegroundColor Cyan
$openPorts = @()
$scanned = 0

foreach ($port in $portList) {
    $scanned++
    $percent = [Math]::Round(($scanned / $portList.Count) * 100)
    Write-Progress -Activity "Scanning ports" -Status "$percent% Complete" -PercentComplete $percent
    
    if (Test-Port -Host $Target -Port $port -Timeout $Timeout) {
        $service = if ($commonPortList.ContainsKey($port)) { $commonPortList[$port] } else { "Unknown" }
        $openPorts += [PSCustomObject]@{
            Port = $port
            Service = $service
            State = "Open"
        }
        Write-Host "  ✓ Port $port" -NoNewline -ForegroundColor Green
        Write-Host " - $service" -ForegroundColor Gray
    }
}

Write-Progress -Activity "Scanning ports" -Completed

# Summary
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Scan Results" -ForegroundColor Green -NoNewline
Write-Host "                           ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

if ($openPorts.Count -eq 0) {
    Write-Host "No open ports found" -ForegroundColor Yellow
} else {
    Write-Host "Open Ports: " -NoNewline
    Write-Host $openPorts.Count -ForegroundColor Green
    Write-Host ""
    
    $openPorts | Format-Table Port, Service, State -AutoSize
    
    # Save results
    $reportPath = "port-scan_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').csv"
    $openPorts | Export-Csv -Path $reportPath -NoTypeInformation
    Write-Host "Results saved to: $reportPath" -ForegroundColor Cyan
}

Write-Host ""

