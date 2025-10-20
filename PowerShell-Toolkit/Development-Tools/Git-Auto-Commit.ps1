#Requires -Version 5.1

<#
.SYNOPSIS
    Automated git operations with smart commit messages
    
.DESCRIPTION
    Automatically stages, commits, and pushes changes with intelligent commit messages
    based on file changes. Supports batch operations and scheduling.
    
.PARAMETER RepositoryPath
    Path to git repository (default: current directory)
    
.PARAMETER CommitMessage
    Custom commit message (optional - will auto-generate if not provided)
    
.PARAMETER Push
    Automatically push to remote after commit
    
.PARAMETER Branch
    Target branch (default: current branch)
    
.PARAMETER Schedule
    Create scheduled task for auto-commits (Hourly, Daily)
    
.EXAMPLE
    .\Git-Auto-Commit.ps1
    
.EXAMPLE
    .\Git-Auto-Commit.ps1 -Push -CommitMessage "Update documentation"
    
.EXAMPLE
    .\Git-Auto-Commit.ps1 -RepositoryPath "C:\Projects\MyRepo" -Push -Schedule Hourly
    
.NOTES
    Author: PowerShell Toolkit
    Requires: Git installed and in PATH
#>

param(
    [string]$RepositoryPath = (Get-Location).Path,
    [string]$CommitMessage,
    [switch]$Push,
    [string]$Branch,
    [ValidateSet("None", "Hourly", "Daily")]
    [string]$Schedule = "None"
)

$ErrorActionPreference = "Stop"

function Test-GitInstalled {
    try {
        $null = git --version
        return $true
    }
    catch {
        Write-Host "ERROR: Git is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Install Git from: https://git-scm.com/" -ForegroundColor Yellow
        return $false
    }
}

function Test-GitRepository {
    param([string]$Path)
    
    Push-Location $Path
    try {
        $null = git rev-parse --git-dir 2>&1
        Pop-Location
        return $true
    }
    catch {
        Pop-Location
        return $false
    }
}

function Get-GitStatus {
    $status = git status --porcelain
    
    if (-not $status) {
        return $null
    }
    
    $changes = @{
        Modified = @()
        Added = @()
        Deleted = @()
        Untracked = @()
    }
    
    foreach ($line in $status) {
        $statusCode = $line.Substring(0, 2).Trim()
        $file = $line.Substring(3)
        
        switch ($statusCode) {
            "M" { $changes.Modified += $file }
            "A" { $changes.Added += $file }
            "D" { $changes.Deleted += $file }
            "??" { $changes.Untracked += $file }
            default { $changes.Modified += $file }
        }
    }
    
    return $changes
}

function New-SmartCommitMessage {
    param($Changes)
    
    $messages = @()
    
    if ($Changes.Added.Count -gt 0) {
        $messages += "Add $($Changes.Added.Count) file(s)"
    }
    if ($Changes.Modified.Count -gt 0) {
        $messages += "Update $($Changes.Modified.Count) file(s)"
    }
    if ($Changes.Deleted.Count -gt 0) {
        $messages += "Delete $($Changes.Deleted.Count) file(s)"
    }
    if ($Changes.Untracked.Count -gt 0) {
        $messages += "Add $($Changes.Untracked.Count) new file(s)"
    }
    
    if ($messages.Count -eq 0) {
        return "Auto-commit: Update project files"
    }
    
    $message = "Auto-commit: " + ($messages -join ", ")
    
    # Add file details if only a few files
    $totalFiles = $Changes.Added.Count + $Changes.Modified.Count + $Changes.Deleted.Count + $Changes.Untracked.Count
    if ($totalFiles -le 3) {
        $fileList = @()
        $fileList += $Changes.Added
        $fileList += $Changes.Modified
        $fileList += $Changes.Deleted
        $fileList += $Changes.Untracked
        $message += "`n`nFiles: " + ($fileList -join ", ")
    }
    
    return $message
}

function Invoke-GitCommit {
    Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║    Git Auto-Commit Tool" -ForegroundColor Cyan -NoNewline
    Write-Host "              ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Validate Git
    if (-not (Test-GitInstalled)) {
        return $false
    }
    
    # Validate repository
    if (-not (Test-GitRepository -Path $RepositoryPath)) {
        Write-Host "ERROR: Not a git repository: $RepositoryPath" -ForegroundColor Red
        return $false
    }
    
    Push-Location $RepositoryPath
    
    try {
        # Get current branch
        $currentBranch = git rev-parse --abbrev-ref HEAD
        Write-Host "`nCurrent branch: " -NoNewline
        Write-Host $currentBranch -ForegroundColor Green
        
        # Check for changes
        Write-Host "Checking for changes..." -ForegroundColor Yellow
        $changes = Get-GitStatus
        
        if ($null -eq $changes) {
            Write-Host "No changes to commit" -ForegroundColor Green
            return $true
        }
        
        # Display changes
        Write-Host "`nChanges detected:" -ForegroundColor Cyan
        if ($changes.Added.Count -gt 0) {
            Write-Host "  Added:     $($changes.Added.Count) file(s)" -ForegroundColor Green
        }
        if ($changes.Modified.Count -gt 0) {
            Write-Host "  Modified:  $($changes.Modified.Count) file(s)" -ForegroundColor Yellow
        }
        if ($changes.Deleted.Count -gt 0) {
            Write-Host "  Deleted:   $($changes.Deleted.Count) file(s)" -ForegroundColor Red
        }
        if ($changes.Untracked.Count -gt 0) {
            Write-Host "  Untracked: $($changes.Untracked.Count) file(s)" -ForegroundColor Cyan
        }
        
        # Stage all changes
        Write-Host "`nStaging changes..." -ForegroundColor Yellow
        git add -A
        Write-Host "✓ All changes staged" -ForegroundColor Green
        
        # Generate or use provided commit message
        if (-not $CommitMessage) {
            $CommitMessage = New-SmartCommitMessage -Changes $changes
        }
        
        Write-Host "`nCommit message:" -ForegroundColor Cyan
        Write-Host $CommitMessage -ForegroundColor White
        
        # Commit
        Write-Host "`nCommitting..." -ForegroundColor Yellow
        git commit -m $CommitMessage
        Write-Host "✓ Changes committed successfully" -ForegroundColor Green
        
        # Push if requested
        if ($Push) {
            Write-Host "`nPushing to remote..." -ForegroundColor Yellow
            
            $targetBranch = if ($Branch) { $Branch } else { $currentBranch }
            
            try {
                git push origin $targetBranch
                Write-Host "✓ Successfully pushed to origin/$targetBranch" -ForegroundColor Green
            }
            catch {
                Write-Host "WARNING: Push failed. Check your remote configuration." -ForegroundColor Yellow
                Write-Host $_.Exception.Message -ForegroundColor Red
            }
        }
        
        Write-Host "`n✓ Auto-commit completed successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "`nERROR: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    finally {
        Pop-Location
    }
}

function New-AutoCommitSchedule {
    param([string]$Frequency, [string]$RepoPath)
    
    $TaskName = "Git-Auto-Commit-$($RepoPath -replace '[:\\]', '-')"
    
    # Check if task exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Host "Removing existing scheduled task..." -ForegroundColor Yellow
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }
    
    $scriptPath = $MyInvocation.MyCommand.Path
    $arguments = "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`" -RepositoryPath `"$RepoPath`" -Push"
    
    # Create trigger
    switch ($Frequency) {
        "Hourly" { 
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        "Daily" { 
            $Trigger = New-ScheduledTaskTrigger -Daily -At 6:00PM
        }
    }
    
    $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $arguments
    $Settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType InteractiveOrPassword -RunLevel Limited
    
    Register-ScheduledTask -TaskName $TaskName -Action $Action -Trigger $Trigger -Settings $Settings -Principal $Principal -Description "Auto-commit for $RepoPath" | Out-Null
    
    Write-Host "`n✓ Scheduled task created: $Frequency auto-commits" -ForegroundColor Green
}

# Main execution
$success = Invoke-GitCommit

if ($success -and $Schedule -ne "None") {
    New-AutoCommitSchedule -Frequency $Schedule -RepoPath $RepositoryPath
}

Write-Host ""

