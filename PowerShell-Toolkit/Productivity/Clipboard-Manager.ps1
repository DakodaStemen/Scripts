#Requires -Version 5.1

<#
.SYNOPSIS
    Clipboard history manager with search
.DESCRIPTION
    Tracks clipboard history, allows searching and restoring previous clipboard entries
.PARAMETER Show
    Show clipboard history
.PARAMETER Clear
    Clear clipboard history
.PARAMETER Save
    Save clipboard history to file
.PARAMETER Load
    Load clipboard history from file
.PARAMETER Search
    Search clipboard history for text
.EXAMPLE
    .\Clipboard-Manager.ps1 -Show
.EXAMPLE
    .\Clipboard-Manager.ps1 -Search "password"
.NOTES
    Author: PowerShell Toolkit
    Runs in background to monitor clipboard
#>

param(
    [switch]$Show,
    [switch]$Clear,
    [switch]$Save,
    [string]$Load,
    [string]$Search
)

Add-Type -AssemblyName System.Windows.Forms

$historyFile = "$PSScriptRoot\clipboard-history.json"
$maxEntries = 50

function Get-ClipboardHistory {
    if (Test-Path $historyFile) {
        return Get-Content $historyFile | ConvertFrom-Json
    }
    return @()
}

function Add-ClipboardEntry {
    param([string]$Text)
    
    $history = @(Get-ClipboardHistory)
    
    # Don't add if it's the same as the last entry
    if ($history.Count -gt 0 -and $history[0].Text -eq $Text) {
        return
    }
    
    $entry = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Text = $Text
        Length = $Text.Length
    }
    
    $history = @($entry) + $history | Select-Object -First $maxEntries
    $history | ConvertTo-Json | Out-File -FilePath $historyFile -Encoding UTF8
}

function Show-ClipboardHistory {
    $history = Get-ClipboardHistory
    
    if ($history.Count -eq 0) {
        Write-Host "Clipboard history is empty" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║      Clipboard History" -ForegroundColor Cyan -NoNewline
    Write-Host "                          ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $counter = 1
    foreach ($entry in $history) {
        $preview = if ($entry.Text.Length -gt 60) {
            $entry.Text.Substring(0, 57) + "..."
        } else {
            $entry.Text
        }
        
        Write-Host "$counter. " -NoNewline -ForegroundColor Gray
        Write-Host "[$($entry.Timestamp)] " -NoNewline -ForegroundColor Gray
        Write-Host $preview -ForegroundColor White
        $counter++
    }
    
    Write-Host "`nTotal entries: $($history.Count)" -ForegroundColor Cyan
    Write-Host ""
}

function Search-ClipboardHistory {
    param([string]$SearchTerm)
    
    $history = Get-ClipboardHistory
    $results = $history | Where-Object { $_.Text -like "*$SearchTerm*" }
    
    if ($results.Count -eq 0) {
        Write-Host "No results found for: $SearchTerm" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nFound $($results.Count) result(s):" -ForegroundColor Green
    Write-Host ""
    
    $counter = 1
    foreach ($entry in $results) {
        Write-Host "$counter. " -NoNewline -ForegroundColor Gray
        Write-Host "[$($entry.Timestamp)]" -ForegroundColor Gray
        Write-Host "   $($entry.Text)" -ForegroundColor White
        Write-Host ""
        $counter++
    }
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Clipboard Manager" -ForegroundColor Cyan -NoNewline
Write-Host "                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($Show) {
    Show-ClipboardHistory
}
elseif ($Clear) {
    Remove-Item $historyFile -ErrorAction SilentlyContinue
    Write-Host "`n✓ Clipboard history cleared" -ForegroundColor Green
}
elseif ($Search) {
    Search-ClipboardHistory -SearchTerm $Search
}
elseif ($Save) {
    $exportPath = "clipboard-export_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').json"
    Copy-Item $historyFile $exportPath
    Write-Host "`n✓ History saved to: $exportPath" -ForegroundColor Green
}
elseif ($Load) {
    if (Test-Path $Load) {
        Copy-Item $Load $historyFile -Force
        Write-Host "`n✓ History loaded from: $Load" -ForegroundColor Green
    } else {
        Write-Host "`n✗ File not found: $Load" -ForegroundColor Red
    }
}
else {
    Write-Host ""
    Write-Host "Monitoring clipboard... (Press Ctrl+C to stop)" -ForegroundColor Yellow
    Write-Host ""
    
    $lastClipboard = ""
    $monitorCount = 0
    
    try {
        while ($true) {
            try {
                $currentClipboard = [System.Windows.Forms.Clipboard]::GetText()
                
                if ($currentClipboard -and $currentClipboard -ne $lastClipboard) {
                    $monitorCount++
                    Write-Host "[$monitorCount] " -NoNewline -ForegroundColor Cyan
                    $preview = if ($currentClipboard.Length -gt 50) {
                        $currentClipboard.Substring(0, 47) + "..."
                    } else {
                        $currentClipboard
                    }
                    Write-Host $preview -ForegroundColor White
                    
                    Add-ClipboardEntry -Text $currentClipboard
                    $lastClipboard = $currentClipboard
                }
            }
            catch {
                # Clipboard might be locked, skip this iteration
            }
            
            Start-Sleep -Milliseconds 500
        }
    }
    catch {
        Write-Host "`n✓ Monitoring stopped" -ForegroundColor Green
    }
}

Write-Host ""

