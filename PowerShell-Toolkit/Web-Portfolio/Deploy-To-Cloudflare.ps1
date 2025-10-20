#Requires -Version 5.1

<#
.SYNOPSIS
    Deploy to Cloudflare Pages
.DESCRIPTION
    One-click deployment to Cloudflare Pages with build automation
.PARAMETER ProjectPath
    Path to project directory
.PARAMETER BuildCommand
    Build command (e.g., "npm run build")
.PARAMETER OutputDir
    Build output directory (default: dist)
.EXAMPLE
    .\Deploy-To-Cloudflare.ps1 -ProjectPath "C:\Projects\MyApp" -BuildCommand "npm run build"
.NOTES
    Author: PowerShell Toolkit
    Requires: Wrangler CLI installed (npm install -g wrangler)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectPath,
    [string]$BuildCommand = "npm run build",
    [string]$OutputDir = "dist"
)

Write-Host "╔═══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Cloudflare Pages Deploy" -ForegroundColor Cyan -NoNewline
Write-Host "          ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Cyan

Push-Location $ProjectPath

try {
    Write-Host "`n→ Building project..." -ForegroundColor Yellow
    Invoke-Expression $BuildCommand
    Write-Host "✓ Build complete" -ForegroundColor Green
    
    Write-Host "`n→ Deploying to Cloudflare Pages..." -ForegroundColor Yellow
    wrangler pages deploy $OutputDir
    Write-Host "`n✓ Deployment complete!" -ForegroundColor Green
}
catch {
    Write-Host "✗ Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    Pop-Location
}

