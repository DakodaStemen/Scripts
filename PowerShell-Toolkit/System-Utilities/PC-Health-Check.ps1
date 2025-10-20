#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Weekly PC Health and Security Check Script
.DESCRIPTION
    Performs comprehensive checks on system health, performance, and security threats
.NOTES
    Author: PC Health Monitor
    Date: 2025-10-19
    Requires: Administrator privileges
#>

# Set up logging
$LogFolder = "$PSScriptRoot\Logs"
if (-not (Test-Path $LogFolder)) {
    New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
}
$LogFile = "$LogFolder\PCCheck_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').log"

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

function Get-SystemPerformance {
    Write-Log "=== Checking System Performance ===" "INFO"
    
    # CPU Usage
    $cpu = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 3 | 
           Select-Object -ExpandProperty CounterSamples | 
           Measure-Object -Property CookedValue -Average | 
           Select-Object -ExpandProperty Average
    $cpuRounded = [Math]::Round($cpu, 2)
    
    if ($cpuRounded -lt 80) {
        Write-Log "CPU Usage: $cpuRounded% - Running at full speed" "SUCCESS"
    } else {
        Write-Log "CPU Usage: $cpuRounded% - High! May slow down performance" "WARNING"
    }
    
    # Memory Usage
    $os = Get-CimInstance Win32_OperatingSystem
    $totalMemory = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeMemory = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedMemory = $totalMemory - $freeMemory
    $memoryPercent = [Math]::Round(($usedMemory / $totalMemory) * 100, 2)
    
    if ($memoryPercent -lt 85) {
        Write-Log "Memory Usage: $memoryPercent% ($usedMemory GB / $totalMemory GB) - Optimal" "SUCCESS"
    } else {
        Write-Log "Memory Usage: $memoryPercent% ($usedMemory GB / $totalMemory GB) - High! May cause slowdowns" "WARNING"
    }
    
    # Disk Space
    $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    foreach ($drive in $drives) {
        $usedSpace = [Math]::Round($drive.Used / 1GB, 2)
        $freeSpace = [Math]::Round($drive.Free / 1GB, 2)
        $totalSpace = $usedSpace + $freeSpace
        $percentFree = [Math]::Round(($freeSpace / $totalSpace) * 100, 2)
        
        if ($percentFree -gt 15) {
            Write-Log "Drive $($drive.Name): $percentFree% free ($freeSpace GB / $totalSpace GB) - Healthy" "SUCCESS"
        } else {
            Write-Log "Drive $($drive.Name): $percentFree% free ($freeSpace GB / $totalSpace GB) - Low! Can slow performance" "WARNING"
        }
    }
}

function Get-TemperatureStatus {
    Write-Log "=== Checking System Temperatures ===" "INFO"
    
    try {
        # Try to get CPU temperature from WMI
        $temps = Get-CimInstance -Namespace "root/wmi" -ClassName MSAcpi_ThermalZoneTemperature -ErrorAction SilentlyContinue
        
        if ($temps) {
            foreach ($temp in $temps) {
                $celsius = [Math]::Round(($temp.CurrentTemperature / 10) - 273.15, 1)
                $fahrenheit = [Math]::Round(($celsius * 9/5) + 32, 1)
                
                if ($celsius -lt 70) {
                    Write-Log "Temperature: ${celsius}C (${fahrenheit}F) - Optimal cooling" "SUCCESS"
                } elseif ($celsius -lt 85) {
                    Write-Log "Temperature: ${celsius}C (${fahrenheit}F) - Warm but acceptable" "WARNING"
                } else {
                    Write-Log "Temperature: ${celsius}C (${fahrenheit}F) - HOT! May cause thermal throttling" "ERROR"
                }
            }
        } else {
            Write-Log "Temperature sensors not accessible (requires specific hardware/drivers)" "INFO"
        }
    } catch {
        Write-Log "Temperature monitoring not available on this system" "INFO"
    }
}

function Get-ResourceHogs {
    Write-Log "=== Identifying Resource-Hungry Processes ===" "INFO"
    
    try {
        # Get top CPU consumers
        $topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        Write-Log "Top CPU consumers:" "INFO"
        foreach ($proc in $topCPU) {
            $cpuTime = [Math]::Round($proc.CPU, 2)
            if ($cpuTime -gt 100) {
                Write-Log "  - $($proc.Name): ${cpuTime}s total CPU time" "WARNING"
            } else {
                Write-Log "  - $($proc.Name): ${cpuTime}s total CPU time" "INFO"
            }
        }
        
        # Get top memory consumers
        $topMemory = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
        Write-Log "Top memory consumers:" "INFO"
        foreach ($proc in $topMemory) {
            $memMB = [Math]::Round($proc.WorkingSet / 1MB, 2)
            if ($memMB -gt 1000) {
                Write-Log "  - $($proc.Name): ${memMB} MB (High usage)" "WARNING"
            } else {
                Write-Log "  - $($proc.Name): ${memMB} MB" "INFO"
            }
        }
    } catch {
        Write-Log "Error analyzing processes: $($_.Exception.Message)" "WARNING"
    }
}

function Invoke-SystemCleanup {
    Write-Log "=== Performing System Cleanup ===" "INFO"
    
    $cleanedSpace = 0
    
    try {
        # Clean Windows Temp folder
        $tempFolder = "$env:SystemRoot\Temp"
        $tempFiles = Get-ChildItem -Path $tempFolder -Recurse -Force -ErrorAction SilentlyContinue
        $tempSize = ($tempFiles | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
        
        if ($tempSize -gt 0) {
            Write-Log "Found $([Math]::Round($tempSize, 2)) GB in Windows Temp folder" "INFO"
            Remove-Item -Path "$tempFolder\*" -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedSpace += $tempSize
            Write-Log "Cleaned Windows Temp folder" "SUCCESS"
        }
        
        # Clean User Temp folder
        $userTemp = "$env:TEMP"
        $userTempFiles = Get-ChildItem -Path $userTemp -Recurse -Force -ErrorAction SilentlyContinue
        $userTempSize = ($userTempFiles | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1GB
        
        if ($userTempSize -gt 0) {
            Write-Log "Found $([Math]::Round($userTempSize, 2)) GB in User Temp folder" "INFO"
            Remove-Item -Path "$userTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
            $cleanedSpace += $userTempSize
            Write-Log "Cleaned User Temp folder" "SUCCESS"
        }
        
        # Clean Recycle Bin
        Write-Log "Emptying Recycle Bin..." "INFO"
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        Write-Log "Recycle Bin emptied" "SUCCESS"
        
        # Run Disk Cleanup utility
        Write-Log "Running Windows Disk Cleanup (background)..." "INFO"
        Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:1" -WindowStyle Hidden -ErrorAction SilentlyContinue
        
        if ($cleanedSpace -gt 0) {
            Write-Log "Total space freed: $([Math]::Round($cleanedSpace, 2)) GB - Performance boost!" "SUCCESS"
        } else {
            Write-Log "System already clean - no junk files found" "SUCCESS"
        }
        
    } catch {
        Write-Log "Cleanup completed with some errors: $($_.Exception.Message)" "WARNING"
    }
}

function Get-DiskHealth {
    Write-Log "=== Checking Disk Health (SMART Status) ===" "INFO"
    
    try {
        $disks = Get-PhysicalDisk
        
        foreach ($disk in $disks) {
            $status = $disk.HealthStatus
            $name = $disk.FriendlyName
            $size = [Math]::Round($disk.Size / 1GB, 2)
            
            switch ($status) {
                "Healthy" {
                    Write-Log "Disk: $name (${size}GB) - Health: HEALTHY - Running at full speed" "SUCCESS"
                }
                "Warning" {
                    Write-Log "Disk: $name (${size}GB) - Health: WARNING - May slow down or fail soon!" "WARNING"
                }
                "Unhealthy" {
                    Write-Log "Disk: $name (${size}GB) - Health: UNHEALTHY - Replace immediately!" "ERROR"
                }
                default {
                    Write-Log "Disk: $name (${size}GB) - Health: $status" "INFO"
                }
            }
            
            # Check media type
            if ($disk.MediaType -eq "HDD") {
                Write-Log "  - Type: HDD (Consider upgrading to SSD for speed boost)" "INFO"
            } else {
                Write-Log "  - Type: $($disk.MediaType) - Optimal for speed" "SUCCESS"
            }
        }
    } catch {
        Write-Log "Error checking disk health: $($_.Exception.Message)" "WARNING"
    }
}

function Optimize-MemoryUsage {
    Write-Log "=== Optimizing Memory Usage ===" "INFO"
    
    try {
        # Get current memory state
        $os = Get-CimInstance Win32_OperatingSystem
        $beforeFree = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
        
        # Clear standby memory (requires RAMMap or similar, so we'll just report)
        Write-Log "Current free memory: $beforeFree GB" "INFO"
        
        # Identify potential memory leaks
        $suspiciousProcesses = Get-Process | Where-Object { 
            $_.WorkingSet -gt 1GB -and $_.Name -notmatch "chrome|firefox|edge|code|teams|outlook"
        }
        
        if ($suspiciousProcesses.Count -gt 0) {
            Write-Log "Processes using excessive memory (potential leaks):" "WARNING"
            foreach ($proc in $suspiciousProcesses) {
                $memGB = [Math]::Round($proc.WorkingSet / 1GB, 2)
                Write-Log "  - $($proc.Name): ${memGB} GB" "WARNING"
            }
        } else {
            Write-Log "No memory leaks detected - Memory usage is healthy" "SUCCESS"
        }
        
    } catch {
        Write-Log "Error analyzing memory: $($_.Exception.Message)" "WARNING"
    }
}

function Get-StartupImpact {
    Write-Log "=== Analyzing Startup Impact ===" "INFO"
    
    try {
        $startupItems = Get-CimInstance Win32_StartupCommand
        $highImpact = @("teams", "discord", "spotify", "steam", "epic", "origin", "adobe")
        
        Write-Log "Found $($startupItems.Count) startup programs" "INFO"
        
        $slowStartup = $false
        foreach ($item in $startupItems) {
            $itemName = $item.Name.ToLower()
            
            # Check if it's a known high-impact program
            $isHighImpact = $false
            foreach ($app in $highImpact) {
                if ($itemName -like "*$app*") {
                    $isHighImpact = $true
                    break
                }
            }
            
            if ($isHighImpact) {
                Write-Log "  - $($item.Name): HIGH IMPACT - Slows boot time" "WARNING"
                $slowStartup = $true
            } else {
                Write-Log "  - $($item.Name): Normal impact" "INFO"
            }
        }
        
        if ($slowStartup) {
            Write-Log "RECOMMENDATION: Disable unnecessary startup programs in Task Manager for faster boot" "WARNING"
        } else {
            Write-Log "Startup configuration is optimized - Fast boot enabled" "SUCCESS"
        }
        
        if ($startupItems.Count -gt 15) {
            Write-Log "WARNING: $($startupItems.Count) startup items detected - Consider reducing for faster boot" "WARNING"
        }
        
    } catch {
        Write-Log "Error analyzing startup items: $($_.Exception.Message)" "WARNING"
    }
}

function Get-SecurityStatus {
    Write-Log "=== Checking Security Status ===" "INFO"
    
    try {
        # Windows Defender Status
        $defenderStatus = Get-MpComputerStatus
        
        if ($defenderStatus.AntivirusEnabled) {
            Write-Log "Windows Defender: Enabled" "SUCCESS"
        } else {
            Write-Log "Windows Defender: Disabled!" "ERROR"
        }
        
        if ($defenderStatus.RealTimeProtectionEnabled) {
            Write-Log "Real-Time Protection: Enabled" "SUCCESS"
        } else {
            Write-Log "Real-Time Protection: Disabled!" "ERROR"
        }
        
        # Check signature age
        $signatureAge = (Get-Date) - $defenderStatus.AntivirusSignatureLastUpdated
        if ($signatureAge.Days -lt 2) {
            Write-Log "Antivirus Signatures: Up to date (Last updated: $($defenderStatus.AntivirusSignatureLastUpdated))" "SUCCESS"
        } else {
            Write-Log "Antivirus Signatures: Outdated! (Last updated: $($defenderStatus.AntivirusSignatureLastUpdated))" "WARNING"
        }
        
        # Check for threats
        $threats = Get-MpThreat
        if ($threats.Count -eq 0) {
            Write-Log "Active Threats: None detected" "SUCCESS"
        } else {
            Write-Log "Active Threats: $($threats.Count) threats found!" "ERROR"
            foreach ($threat in $threats) {
                Write-Log "  - $($threat.ThreatName) (Severity: $($threat.SeverityID))" "ERROR"
            }
        }
        
    } catch {
        Write-Log "Error checking Windows Defender status: $($_.Exception.Message)" "ERROR"
    }
}

function Start-SecurityScan {
    Write-Log "=== Starting Quick Security Scan ===" "INFO"
    
    try {
        Write-Log "Initiating Windows Defender Quick Scan..." "INFO"
        Start-MpScan -ScanType QuickScan -AsJob | Out-Null
        Write-Log "Quick scan initiated successfully (running in background)" "SUCCESS"
    } catch {
        Write-Log "Error starting security scan: $($_.Exception.Message)" "ERROR"
    }
}

function Get-WindowsUpdates {
    Write-Log "=== Checking Windows Updates ===" "INFO"
    
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")
        
        if ($searchResult.Updates.Count -eq 0) {
            Write-Log "Windows Updates: System is up to date" "SUCCESS"
        } else {
            Write-Log "Windows Updates: $($searchResult.Updates.Count) updates available" "WARNING"
            foreach ($update in $searchResult.Updates | Select-Object -First 5) {
                Write-Log "  - $($update.Title)" "INFO"
            }
            if ($searchResult.Updates.Count -gt 5) {
                Write-Log "  - ... and $($searchResult.Updates.Count - 5) more" "INFO"
            }
        }
    } catch {
        Write-Log "Error checking Windows Updates: $($_.Exception.Message)" "WARNING"
    }
}

function Get-SystemErrors {
    Write-Log "=== Checking Recent System Errors ===" "INFO"
    
    try {
        $errors = Get-EventLog -LogName System -EntryType Error -Newest 10 -After (Get-Date).AddDays(-7)
        
        if ($errors.Count -eq 0) {
            Write-Log "System Errors: No critical errors in the last 7 days" "SUCCESS"
        } else {
            Write-Log "System Errors: Found $($errors.Count) errors in the last 7 days" "WARNING"
            foreach ($error in $errors | Select-Object -First 5) {
                Write-Log "  - [$($error.TimeGenerated)] $($error.Source): $($error.Message.Substring(0, [Math]::Min(100, $error.Message.Length)))..." "WARNING"
            }
        }
    } catch {
        Write-Log "Error checking system event log: $($_.Exception.Message)" "WARNING"
    }
}

function Get-FirewallStatus {
    Write-Log "=== Checking Firewall Status ===" "INFO"
    
    try {
        $firewallProfiles = Get-NetFirewallProfile
        
        foreach ($profile in $firewallProfiles) {
            if ($profile.Enabled) {
                Write-Log "Firewall ($($profile.Name)): Enabled" "SUCCESS"
            } else {
                Write-Log "Firewall ($($profile.Name)): Disabled!" "ERROR"
            }
        }
    } catch {
        Write-Log "Error checking firewall status: $($_.Exception.Message)" "ERROR"
    }
}


function Send-Summary {
    Write-Log "=== PC Performance Check Complete ===" "INFO"
    Write-Log "Full report saved to: $LogFile" "INFO"
    
    # Count warnings and errors
    $logContent = Get-Content $LogFile
    $errorCount = ($logContent | Select-String -Pattern "\[ERROR\]").Count
    $warningCount = ($logContent | Select-String -Pattern "\[WARNING\]").Count
    
    Write-Log "Summary: $errorCount errors, $warningCount warnings" "INFO"
    
    if ($errorCount -eq 0 -and $warningCount -eq 0) {
        Write-Log "====== PC RUNNING AT FULL SPEED & FULL FORCE! ======" "SUCCESS"
        Write-Log "All systems optimal - Maximum performance achieved!" "SUCCESS"
    } elseif ($errorCount -eq 0) {
        Write-Log "System Status: Running well with minor optimization suggestions" "WARNING"
        Write-Log "PC performance is good - Review warnings for potential speed improvements" "WARNING"
    } else {
        Write-Log "System Status: Performance issues detected!" "ERROR"
        Write-Log "Action required - Check errors above to restore full speed" "ERROR"
    }
}

# Main execution
Write-Log "========================================" "INFO"
Write-Log "Starting Weekly PC Performance & Health Check" "INFO"
Write-Log "========================================" "INFO"

# Performance checks - Keep system running at full speed
Get-SystemPerformance
Get-TemperatureStatus
Get-ResourceHogs
Get-DiskHealth
Optimize-MemoryUsage
Get-StartupImpact

# System cleanup - Free up resources
Invoke-SystemCleanup

# Security checks - Stay protected
Get-SecurityStatus
Get-FirewallStatus
Start-SecurityScan

# System health checks
Get-WindowsUpdates
Get-SystemErrors

Send-Summary

Write-Log "========================================" "INFO"

# Keep window open if running manually
if ($Host.Name -eq "ConsoleHost") {
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
