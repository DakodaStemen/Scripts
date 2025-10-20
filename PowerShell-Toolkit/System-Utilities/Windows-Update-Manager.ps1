#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows Update manager and installer
.DESCRIPTION
    Check for, download, and install Windows updates with detailed reporting
.PARAMETER CheckOnly
    Only check for updates, don't install
.PARAMETER InstallAll
    Install all available updates
.PARAMETER DownloadOnly
    Download but don't install updates
.EXAMPLE
    .\Windows-Update-Manager.ps1 -CheckOnly
.EXAMPLE
    .\Windows-Update-Manager.ps1 -InstallAll
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator privileges
#>

param(
    [switch]$CheckOnly,
    [switch]$InstallAll,
    [switch]$DownloadOnly
)

Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Windows Update Manager" -ForegroundColor Cyan -NoNewline
Write-Host "                     ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "Checking for updates..." -ForegroundColor Cyan

try {
    $updateSession = New-Object -ComObject Microsoft.Update.Session
    $updateSearcher = $updateSession.CreateUpdateSearcher()
    
    Write-Host "Searching for available updates..." -ForegroundColor Yellow
    $searchResult = $updateSearcher.Search("IsInstalled=0")
    
    if ($searchResult.Updates.Count -eq 0) {
        Write-Host "`n✓ System is up to date!" -ForegroundColor Green
        Write-Host "No updates available" -ForegroundColor Gray
        exit 0
    }
    
    # Display available updates
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "║      Available Updates" -ForegroundColor Yellow -NoNewline
    Write-Host "                          ║" -ForegroundColor Yellow
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Yellow
    Write-Host ""
    
    Write-Host "Found $($searchResult.Updates.Count) update(s):" -ForegroundColor Cyan
    Write-Host ""
    
    $counter = 1
    foreach ($update in $searchResult.Updates) {
        $sizeMB = [Math]::Round($update.MaxDownloadSize / 1MB, 2)
        Write-Host "$counter. " -NoNewline -ForegroundColor Gray
        Write-Host $update.Title -ForegroundColor White
        Write-Host "   Size: ${sizeMB} MB" -ForegroundColor Gray
        if ($update.IsMandatory) {
            Write-Host "   [MANDATORY]" -ForegroundColor Red
        }
        $counter++
    }
    
    if ($CheckOnly) {
        Write-Host "`nUse -InstallAll to install all updates" -ForegroundColor Yellow
        exit 0
    }
    
    # Download updates
    if ($InstallAll -or $DownloadOnly) {
        Write-Host "`nDownloading updates..." -ForegroundColor Cyan
        
        $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) {
            $updatesToDownload.Add($update) | Out-Null
        }
        
        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesToDownload
        $downloadResult = $downloader.Download()
        
        if ($downloadResult.ResultCode -eq 2) {
            Write-Host "✓ Updates downloaded successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠ Download completed with warnings" -ForegroundColor Yellow
        }
        
        if ($DownloadOnly) {
            Write-Host "`nUpdates downloaded but not installed" -ForegroundColor Yellow
            Write-Host "Use -InstallAll to install" -ForegroundColor Gray
            exit 0
        }
        
        # Install updates
        Write-Host "`nInstalling updates..." -ForegroundColor Cyan
        Write-Host "⚠ This may take several minutes" -ForegroundColor Yellow
        
        $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) {
            if ($update.IsDownloaded) {
                $updatesToInstall.Add($update) | Out-Null
            }
        }
        
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $installResult = $installer.Install()
        
        Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║      Installation Complete" -ForegroundColor Green -NoNewline
        Write-Host "                      ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "Result Code: $($installResult.ResultCode)" -ForegroundColor White
        
        if ($installResult.RebootRequired) {
            Write-Host "`n⚠ REBOOT REQUIRED" -ForegroundColor Yellow
            Write-Host "A system restart is needed to complete the installation" -ForegroundColor Gray
            
            $response = Read-Host "`nReboot now? (Y/N)"
            if ($response -eq 'Y' -or $response -eq 'y') {
                Write-Host "Rebooting in 10 seconds..." -ForegroundColor Yellow
                shutdown /r /t 10
            }
        } else {
            Write-Host "✓ No reboot required" -ForegroundColor Green
        }
    }
    
} catch {
    Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

