#Requires -Version 5.1

<#
.SYNOPSIS
    Fast note-taking from command line
.DESCRIPTION
    Quickly create, view, search, and manage notes from PowerShell
.PARAMETER Add
    Add a new note
.PARAMETER List
    List all notes
.PARAMETER Search
    Search notes
.PARAMETER Delete
    Delete note by ID
.PARAMETER Tag
    Add tag to note
.EXAMPLE
    .\Quick-Notes.ps1 -Add "Remember to call John"
.EXAMPLE
    .\Quick-Notes.ps1 -Search "meeting"
.NOTES
    Author: PowerShell Toolkit
#>

param(
    [string]$Add,
    [switch]$List,
    [string]$Search,
    [int]$Delete,
    [string]$Tag
)

$notesFile = "$PSScriptRoot\quick-notes.json"

function Get-Notes {
    if (Test-Path $notesFile) {
        return Get-Content $notesFile | ConvertFrom-Json
    }
    return @()
}

function Save-Notes {
    param($Notes)
    $Notes | ConvertTo-Json | Out-File -FilePath $notesFile -Encoding UTF8
}

function Add-Note {
    param([string]$Text, [string]$Tag)
    
    $notes = @(Get-Notes)
    $id = if ($notes.Count -gt 0) { ($notes | Measure-Object -Property Id -Maximum).Maximum + 1 } else { 1 }
    
    $note = [PSCustomObject]@{
        Id = $id
        Text = $Text
        Created = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Tags = if ($Tag) { @($Tag) } else { @() }
    }
    
    $notes = @($notes) + @($note)
    Save-Notes -Notes $notes
    
    Write-Host "`n✓ Note added (ID: $id)" -ForegroundColor Green
    Write-Host "  $Text" -ForegroundColor White
}

function Show-Notes {
    $notes = Get-Notes
    
    if ($notes.Count -eq 0) {
        Write-Host "`nNo notes found" -ForegroundColor Yellow
        Write-Host "Add a note with: .\Quick-Notes.ps1 -Add `"Your note`"" -ForegroundColor Gray
        return
    }
    
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Quick Notes" -ForegroundColor Cyan -NoNewline
    Write-Host "                              ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    foreach ($note in $notes | Sort-Object Id -Descending) {
        Write-Host "[ID: $($note.Id)] " -NoNewline -ForegroundColor Yellow
        Write-Host $note.Created -ForegroundColor Gray
        Write-Host "  $($note.Text)" -ForegroundColor White
        if ($note.Tags.Count -gt 0) {
            Write-Host "  Tags: " -NoNewline -ForegroundColor Gray
            Write-Host ($note.Tags -join ", ") -ForegroundColor Cyan
        }
        Write-Host ""
    }
    
    Write-Host "Total notes: $($notes.Count)" -ForegroundColor Cyan
}

function Search-Notes {
    param([string]$SearchTerm)
    
    $notes = Get-Notes
    $results = $notes | Where-Object { $_.Text -like "*$SearchTerm*" -or $_.Tags -contains $SearchTerm }
    
    if ($results.Count -eq 0) {
        Write-Host "`nNo results found" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`nFound $($results.Count) note(s):" -ForegroundColor Green
    Write-Host ""
    
    foreach ($note in $results) {
        Write-Host "[ID: $($note.Id)] " -NoNewline -ForegroundColor Yellow
        Write-Host $note.Text -ForegroundColor White
        Write-Host ""
    }
}

function Remove-Note {
    param([int]$Id)
    
    $notes = @(Get-Notes)
    $noteToDelete = $notes | Where-Object { $_.Id -eq $Id }
    
    if (-not $noteToDelete) {
        Write-Host "`n✗ Note ID $Id not found" -ForegroundColor Red
        return
    }
    
    $notes = $notes | Where-Object { $_.Id -ne $Id }
    Save-Notes -Notes $notes
    
    Write-Host "`n✓ Note deleted (ID: $Id)" -ForegroundColor Green
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         Quick Notes CLI" -ForegroundColor Cyan -NoNewline
Write-Host "                          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan

if ($Add) {
    Add-Note -Text $Add -Tag $Tag
}
elseif ($List) {
    Show-Notes
}
elseif ($Search) {
    Search-Notes -SearchTerm $Search
}
elseif ($Delete) {
    Remove-Note -Id $Delete
}
else {
    Show-Notes
}

Write-Host ""

