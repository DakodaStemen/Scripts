#Requires -Version 5.1

<#
.SYNOPSIS
    Beautiful system information dashboard
    
.DESCRIPTION
    Displays comprehensive system information in an organized, color-coded format
    including CPU, memory, disk, network, and OS details.
    
.PARAMETER ExportPath
    Optional path to export system info to JSON file
    
.PARAMETER ShowProcesses
    Include top running processes in the output
    
.EXAMPLE
    .\System-Info.ps1
    
.EXAMPLE
    .\System-Info.ps1 -ExportPath "C:\system-info.json" -ShowProcesses
    
.NOTES
    Author: PowerShell Toolkit
    No admin rights required
#>

param(
    [string]$ExportPath,
    [switch]$ShowProcesses
)

function Write-Section {
    param([string]$Title)
    Write-Host "`n╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  $Title" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
}

function Write-InfoLine {
    param([string]$Label, [string]$Value, [string]$Color = "White")
    $padding = 25 - $Label.Length
    Write-Host "  $Label" -NoNewline -ForegroundColor Gray
    Write-Host (" " * $padding) -NoNewline
    Write-Host $Value -ForegroundColor $Color
}

function Get-SystemInfo {
    $info = @{}
    
    # Computer Info
    $cs = Get-CimInstance Win32_ComputerSystem
    $os = Get-CimInstance Win32_OperatingSystem
    $bios = Get-CimInstance Win32_BIOS
    $cpu = Get-CimInstance Win32_Processor
    
    # OS Information
    Write-Section "OPERATING SYSTEM"
    $info.OS = @{
        Name = $os.Caption
        Version = $os.Version
        Build = $os.BuildNumber
        Architecture = $os.OSArchitecture
        InstallDate = $os.InstallDate
        LastBoot = $os.LastBootUpTime
    }
    
    Write-InfoLine "OS Name:" $info.OS.Name "Green"
    Write-InfoLine "Version:" "$($info.OS.Version) (Build $($info.OS.Build))" "White"
    Write-InfoLine "Architecture:" $info.OS.Architecture "White"
    
    $uptime = (Get-Date) - $info.OS.LastBoot
    $uptimeStr = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
    Write-InfoLine "Uptime:" $uptimeStr "Yellow"
    
    # Computer Information
    Write-Section "COMPUTER"
    $info.Computer = @{
        Name = $cs.Name
        Domain = $cs.Domain
        Manufacturer = $cs.Manufacturer
        Model = $cs.Model
        Type = $cs.PCSystemType
    }
    
    Write-InfoLine "Computer Name:" $info.Computer.Name "Green"
    Write-InfoLine "Manufacturer:" $info.Computer.Manufacturer "White"
    Write-InfoLine "Model:" $info.Computer.Model "White"
    
    # CPU Information
    Write-Section "PROCESSOR"
    $info.CPU = @{
        Name = $cpu.Name
        Cores = $cpu.NumberOfCores
        LogicalProcessors = $cpu.NumberOfLogicalProcessors
        MaxSpeed = $cpu.MaxClockSpeed
    }
    
    Write-InfoLine "Processor:" $info.CPU.Name "Green"
    Write-InfoLine "Cores:" "$($info.CPU.Cores) cores / $($info.CPU.LogicalProcessors) logical" "White"
    Write-InfoLine "Max Speed:" "$($info.CPU.MaxSpeed) MHz" "White"
    
    # Current CPU Usage
    $cpuUsage = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1 | 
                Select-Object -ExpandProperty CounterSamples | 
                Select-Object -ExpandProperty CookedValue
    $cpuRounded = [Math]::Round($cpuUsage, 1)
    
    $cpuColor = if ($cpuRounded -lt 50) { "Green" } elseif ($cpuRounded -lt 80) { "Yellow" } else { "Red" }
    Write-InfoLine "Current Usage:" "$cpuRounded%" $cpuColor
    
    # Memory Information
    Write-Section "MEMORY"
    $totalRAM = [Math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $freeRAM = [Math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedRAM = $totalRAM - $freeRAM
    $memPercent = [Math]::Round(($usedRAM / $totalRAM) * 100, 1)
    
    $info.Memory = @{
        Total = $totalRAM
        Used = $usedRAM
        Free = $freeRAM
        Percent = $memPercent
    }
    
    Write-InfoLine "Total RAM:" "$totalRAM GB" "Green"
    Write-InfoLine "Used:" "$usedRAM GB" "White"
    Write-InfoLine "Free:" "$freeRAM GB" "White"
    
    $memColor = if ($memPercent -lt 70) { "Green" } elseif ($memPercent -lt 85) { "Yellow" } else { "Red" }
    Write-InfoLine "Usage:" "$memPercent%" $memColor
    
    # Disk Information
    Write-Section "STORAGE"
    $disks = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -ne $null }
    $info.Disks = @()
    
    foreach ($disk in $disks) {
        $totalSpace = [Math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
        $usedSpace = [Math]::Round($disk.Used / 1GB, 2)
        $freeSpace = [Math]::Round($disk.Free / 1GB, 2)
        $percentFree = [Math]::Round(($freeSpace / $totalSpace) * 100, 1)
        
        $info.Disks += @{
            Drive = $disk.Name
            Total = $totalSpace
            Used = $usedSpace
            Free = $freeSpace
            PercentFree = $percentFree
        }
        
        $diskColor = if ($percentFree -gt 20) { "Green" } elseif ($percentFree -gt 10) { "Yellow" } else { "Red" }
        Write-InfoLine "Drive $($disk.Name):\" "$freeSpace GB free of $totalSpace GB ($percentFree% free)" $diskColor
    }
    
    # Physical Disks
    $physicalDisks = Get-PhysicalDisk
    Write-Host ""
    foreach ($pd in $physicalDisks) {
        $sizeGB = [Math]::Round($pd.Size / 1GB, 0)
        $healthColor = if ($pd.HealthStatus -eq "Healthy") { "Green" } else { "Red" }
        Write-InfoLine "$($pd.MediaType):" "$sizeGB GB - $($pd.HealthStatus)" $healthColor
    }
    
    # Network Information
    Write-Section "NETWORK"
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
    $info.Network = @()
    
    foreach ($adapter in $adapters) {
        $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($ipConfig) {
            $info.Network += @{
                Name = $adapter.Name
                Status = $adapter.Status
                Speed = $adapter.LinkSpeed
                IP = $ipConfig.IPAddress
            }
            
            Write-InfoLine "$($adapter.Name):" "$($ipConfig.IPAddress) ($($adapter.LinkSpeed))" "Green"
        }
    }
    
    # Show top processes if requested
    if ($ShowProcesses) {
        Write-Section "TOP PROCESSES (CPU)"
        $topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
        foreach ($proc in $topCPU) {
            $cpuTime = [Math]::Round($proc.CPU, 1)
            $memMB = [Math]::Round($proc.WorkingSet / 1MB, 0)
            Write-InfoLine "$($proc.Name):" "CPU: ${cpuTime}s | RAM: ${memMB}MB" "Yellow"
        }
        
        Write-Section "TOP PROCESSES (MEMORY)"
        $topMem = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 5
        foreach ($proc in $topMem) {
            $memMB = [Math]::Round($proc.WorkingSet / 1MB, 0)
            Write-InfoLine "$($proc.Name):" "${memMB} MB" "Yellow"
        }
    }
    
    # BIOS Information
    Write-Section "BIOS"
    $info.BIOS = @{
        Manufacturer = $bios.Manufacturer
        Version = $bios.SMBIOSBIOSVersion
        ReleaseDate = $bios.ReleaseDate
    }
    
    Write-InfoLine "Manufacturer:" $info.BIOS.Manufacturer "White"
    Write-InfoLine "Version:" $info.BIOS.Version "White"
    
    # Summary
    Write-Section "SUMMARY"
    $totalProcesses = (Get-Process).Count
    $totalServices = (Get-Service).Count
    $runningServices = (Get-Service | Where-Object { $_.Status -eq "Running" }).Count
    
    Write-InfoLine "Processes:" $totalProcesses "White"
    Write-InfoLine "Services:" "$runningServices running / $totalServices total" "White"
    Write-InfoLine "User:" $env:USERNAME "Green"
    
    Write-Host "`n" -NoNewline
    
    return $info
}

# Main execution
Clear-Host
Write-Host "╔═══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         SYSTEM INFORMATION DASHBOARD" -ForegroundColor Cyan -NoNewline
Write-Host "                  ║" -ForegroundColor Cyan
Write-Host "║         $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan -NoNewline
Write-Host "                      ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════╝" -ForegroundColor Cyan

$systemInfo = Get-SystemInfo

# Export if requested
if ($ExportPath) {
    $systemInfo | ConvertTo-Json -Depth 10 | Out-File -FilePath $ExportPath -Encoding UTF8
    Write-Host "System information exported to: $ExportPath" -ForegroundColor Green
}

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

