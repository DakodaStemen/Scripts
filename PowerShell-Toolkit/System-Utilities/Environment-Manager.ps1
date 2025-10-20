#Requires -Version 5.1

<#
.SYNOPSIS
    Environment variable manager
.DESCRIPTION
    View, add, modify, and remove environment variables with ease
.PARAMETER List
    List all environment variables
.PARAMETER Add
    Add new environment variable (format: Name=Value)
.PARAMETER Remove
    Remove environment variable by name
.PARAMETER Search
    Search environment variables
.PARAMETER Scope
    Variable scope: User, Machine, Process (default: User)
.PARAMETER Export
    Export environment variables to file
.EXAMPLE
    .\Environment-Manager.ps1 -List
.EXAMPLE
    .\Environment-Manager.ps1 -Add "MY_VAR=MyValue" -Scope User
.EXAMPLE
    .\Environment-Manager.ps1 -Search "PATH"
.NOTES
    Author: PowerShell Toolkit
    Requires: Administrator for Machine scope
#>

param(
    [switch]$List,
    [string]$Add,
    [string]$Remove,
    [string]$Search,
    [ValidateSet("User", "Machine", "Process")]
    [string]$Scope = "User",
    [switch]$Export
)

function Show-EnvironmentVariables {
    param([string]$ScopeFilter)
    
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║      Environment Variables" -ForegroundColor Cyan -NoNewline
    Write-Host "                      ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    $variables = [Environment]::GetEnvironmentVariables($ScopeFilter)
    $sorted = $variables.GetEnumerator() | Sort-Object Name
    
    Write-Host "Scope: " -NoNewline
    Write-Host $ScopeFilter -ForegroundColor Yellow
    Write-Host "Count: " -NoNewline
    Write-Host $sorted.Count -ForegroundColor Green
    Write-Host ""
    
    foreach ($var in $sorted) {
        Write-Host "$($var.Name) " -NoNewline -ForegroundColor Cyan
        Write-Host "= " -NoNewline -ForegroundColor Gray
        
        # Truncate long values
        $value = $var.Value
        if ($value.Length -gt 80) {
            $value = $value.Substring(0, 77) + "..."
        }
        Write-Host $value -ForegroundColor White
    }
}

function Add-EnvironmentVariable {
    param([string]$VarString, [string]$TargetScope)
    
    if ($VarString -notmatch '^([^=]+)=(.+)$') {
        Write-Host "`n✗ Invalid format. Use: Name=Value" -ForegroundColor Red
        return
    }
    
    $name = $matches[1].Trim()
    $value = $matches[2].Trim()
    
    # Check if exists
    $existing = [Environment]::GetEnvironmentVariable($name, $TargetScope)
    if ($existing) {
        Write-Host "`n⚠ Variable '$name' already exists" -ForegroundColor Yellow
        Write-Host "Current value: $existing" -ForegroundColor Gray
        $response = Read-Host "Overwrite? (Y/N)"
        if ($response -ne 'Y' -and $response -ne 'y') {
            Write-Host "Cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    try {
        [Environment]::SetEnvironmentVariable($name, $value, $TargetScope)
        Write-Host "`n✓ Environment variable set:" -ForegroundColor Green
        Write-Host "  Name:  $name" -ForegroundColor White
        Write-Host "  Value: $value" -ForegroundColor White
        Write-Host "  Scope: $TargetScope" -ForegroundColor Yellow
        
        if ($TargetScope -ne "Process") {
            Write-Host "`nRestart terminal for changes to take effect" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Remove-EnvironmentVariable {
    param([string]$Name, [string]$TargetScope)
    
    $existing = [Environment]::GetEnvironmentVariable($Name, $TargetScope)
    if (-not $existing) {
        Write-Host "`n✗ Variable '$Name' not found in $TargetScope scope" -ForegroundColor Red
        return
    }
    
    Write-Host "`n⚠ About to remove:" -ForegroundColor Yellow
    Write-Host "  Name:  $Name" -ForegroundColor White
    Write-Host "  Value: $existing" -ForegroundColor Gray
    Write-Host "  Scope: $TargetScope" -ForegroundColor Yellow
    
    $response = Read-Host "`nConfirm removal? (Y/N)"
    if ($response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Cancelled" -ForegroundColor Yellow
        return
    }
    
    try {
        [Environment]::SetEnvironmentVariable($Name, $null, $TargetScope)
        Write-Host "`n✓ Environment variable removed" -ForegroundColor Green
    }
    catch {
        Write-Host "`n✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Search-EnvironmentVariables {
    param([string]$SearchTerm)
    
    Write-Host "`nSearching for: $SearchTerm" -ForegroundColor Cyan
    Write-Host ""
    
    $found = $false
    
    foreach ($scope in @("User", "Machine", "Process")) {
        $variables = [Environment]::GetEnvironmentVariables($scope)
        $matches = $variables.GetEnumerator() | Where-Object {
            $_.Name -like "*$SearchTerm*" -or $_.Value -like "*$SearchTerm*"
        }
        
        if ($matches) {
            Write-Host "[$scope Scope]" -ForegroundColor Yellow
            foreach ($var in $matches) {
                Write-Host "  $($var.Name) = $($var.Value)" -ForegroundColor White
            }
            Write-Host ""
            $found = $true
        }
    }
    
    if (-not $found) {
        Write-Host "No matches found" -ForegroundColor Yellow
    }
}

function Export-EnvironmentVariables {
    $exportPath = "environment-vars_$(Get-Date -Format 'yyyy-MM-dd_HHmmss').json"
    
    $export = @{
        User = [Environment]::GetEnvironmentVariables("User")
        Machine = [Environment]::GetEnvironmentVariables("Machine")
        Process = [Environment]::GetEnvironmentVariables("Process")
        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $export | ConvertTo-Json -Depth 10 | Out-File -FilePath $exportPath -Encoding UTF8
    
    Write-Host "`n✓ Environment variables exported to:" -ForegroundColor Green
    Write-Host "  $exportPath" -ForegroundColor White
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Environment Variable Manager" -ForegroundColor Cyan -NoNewline
Write-Host "               ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($List) {
    Show-EnvironmentVariables -ScopeFilter $Scope
}
elseif ($Add) {
    Add-EnvironmentVariable -VarString $Add -TargetScope $Scope
}
elseif ($Remove) {
    Remove-EnvironmentVariable -Name $Remove -TargetScope $Scope
}
elseif ($Search) {
    Search-EnvironmentVariables -SearchTerm $Search
}
elseif ($Export) {
    Export-EnvironmentVariables
}
else {
    Show-EnvironmentVariables -ScopeFilter $Scope
}

Write-Host ""

