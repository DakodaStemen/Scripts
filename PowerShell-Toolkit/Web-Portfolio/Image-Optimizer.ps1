#Requires -Version 5.1

<#
.SYNOPSIS
    Compress and optimize images for web
    
.DESCRIPTION
    Reduces image file sizes while maintaining quality. Supports JPG, PNG, and WebP.
    Can process individual files or entire directories.
    
.PARAMETER Path
    Path to image file or directory
    
.PARAMETER Quality
    Output quality 1-100 (default: 85)
    
.PARAMETER Resize
    Resize images to max width/height (optional)
    
.PARAMETER OutputFormat
    Convert to format: Original, JPG, PNG, WebP (default: Original)
    
.PARAMETER Recursive
    Process subdirectories
    
.PARAMETER OutputPath
    Custom output directory (default: creates "optimized" subfolder)
    
.EXAMPLE
    .\Image-Optimizer.ps1 -Path "C:\images" -Quality 85
    
.EXAMPLE
    .\Image-Optimizer.ps1 -Path "C:\photo.jpg" -Resize 1920 -OutputFormat WebP
    
.NOTES
    Author: PowerShell Toolkit
    Uses .NET Image libraries (no external dependencies)
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Path,
    
    [ValidateRange(1,100)]
    [int]$Quality = 85,
    
    [int]$Resize,
    
    [ValidateSet("Original", "JPG", "PNG", "WebP")]
    [string]$OutputFormat = "Original",
    
    [switch]$Recursive,
    
    [string]$OutputPath
)

Add-Type -AssemblyName System.Drawing

$supportedFormats = @(".jpg", ".jpeg", ".png", ".bmp", ".gif")

function Write-Header {
    Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Image Optimizer for Web" -ForegroundColor Cyan -NoNewline
    Write-Host "                   ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

function Format-FileSize {
    param([long]$Size)
    
    if ($Size -gt 1MB) {
        return "{0:N2} MB" -f ($Size / 1MB)
    }
    elseif ($Size -gt 1KB) {
        return "{0:N2} KB" -f ($Size / 1KB)
    }
    else {
        return "$Size bytes"
    }
}

function Get-ImageCodec {
    param([string]$Format)
    
    $codecs = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders()
    
    switch ($Format.ToLower()) {
        "jpg" { return $codecs | Where-Object { $_.MimeType -eq "image/jpeg" } }
        "png" { return $codecs | Where-Object { $_.MimeType -eq "image/png" } }
        "bmp" { return $codecs | Where-Object { $_.MimeType -eq "image/bmp" } }
        "gif" { return $codecs | Where-Object { $_.MimeType -eq "image/gif" } }
        default { return $codecs[0] }
    }
}

function Optimize-Image {
    param(
        [string]$InputPath,
        [string]$OutputPath,
        [int]$Quality,
        [int]$MaxSize,
        [string]$Format
    )
    
    try {
        $image = [System.Drawing.Image]::FromFile($InputPath)
        $originalWidth = $image.Width
        $originalHeight = $image.Height
        
        # Calculate new dimensions if resize is needed
        if ($MaxSize -and ($originalWidth -gt $MaxSize -or $originalHeight -gt $MaxSize)) {
            if ($originalWidth -gt $originalHeight) {
                $newWidth = $MaxSize
                $newHeight = [int](($originalHeight / $originalWidth) * $MaxSize)
            } else {
                $newHeight = $MaxSize
                $newWidth = [int](($originalWidth / $originalHeight) * $MaxSize)
            }
        } else {
            $newWidth = $originalWidth
            $newHeight = $originalHeight
        }
        
        # Create new bitmap
        $newImage = New-Object System.Drawing.Bitmap($newWidth, $newHeight)
        $graphics = [System.Drawing.Graphics]::FromImage($newImage)
        
        # Set high quality rendering
        $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        
        # Draw resized image
        $graphics.DrawImage($image, 0, 0, $newWidth, $newHeight)
        
        # Determine output format
        $outputFormat = if ($Format -eq "Original") {
            [System.IO.Path]::GetExtension($InputPath).TrimStart('.')
        } else {
            $Format
        }
        
        # Get encoder
        $codec = Get-ImageCodec -Format $outputFormat
        
        # Set quality
        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality, 
            $Quality
        )
        
        # Change extension if format changed
        if ($Format -ne "Original") {
            $OutputPath = [System.IO.Path]::ChangeExtension($OutputPath, $outputFormat)
        }
        
        # Save optimized image
        $newImage.Save($OutputPath, $codec, $encoderParams)
        
        # Cleanup
        $graphics.Dispose()
        $newImage.Dispose()
        $image.Dispose()
        
        return $true
    }
    catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($image) { $image.Dispose() }
        if ($newImage) { $newImage.Dispose() }
        if ($graphics) { $graphics.Dispose() }
        return $false
    }
}

# Main execution
Write-Header

# Validate input path
if (-not (Test-Path $Path)) {
    Write-Host "Error: Path not found: $Path" -ForegroundColor Red
    exit 1
}

# Get files
$files = @()
if ((Get-Item $Path).PSIsContainer) {
    # Directory
    $files = if ($Recursive) {
        Get-ChildItem -Path $Path -File -Recurse | Where-Object { $supportedFormats -contains $_.Extension.ToLower() }
    } else {
        Get-ChildItem -Path $Path -File | Where-Object { $supportedFormats -contains $_.Extension.ToLower() }
    }
    
    # Set output directory
    if (-not $OutputPath) {
        $OutputPath = Join-Path $Path "optimized"
    }
} else {
    # Single file
    if ($supportedFormats -contains ([System.IO.Path]::GetExtension($Path).ToLower())) {
        $files = @(Get-Item $Path)
    } else {
        Write-Host "Error: Unsupported file format. Supported: $($supportedFormats -join ', ')" -ForegroundColor Red
        exit 1
    }
    
    # Set output directory
    if (-not $OutputPath) {
        $OutputPath = Join-Path (Split-Path $Path) "optimized"
    }
}

if ($files.Count -eq 0) {
    Write-Host "No supported image files found" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found: " -NoNewline
Write-Host "$($files.Count) image(s)" -ForegroundColor Green
Write-Host "Quality: " -NoNewline
Write-Host "$Quality%" -ForegroundColor Yellow
if ($Resize) {
    Write-Host "Max size: " -NoNewline
    Write-Host "${Resize}px" -ForegroundColor Yellow
}
if ($OutputFormat -ne "Original") {
    Write-Host "Convert to: " -NoNewline
    Write-Host $OutputFormat -ForegroundColor Yellow
}
Write-Host "Output: " -NoNewline
Write-Host $OutputPath -ForegroundColor Cyan
Write-Host ""

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

# Process images
$processed = 0
$totalSaved = 0
$successCount = 0

Write-Host "Processing images..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
    $processed++
    Write-Progress -Activity "Optimizing images" -Status "Processing $($file.Name)" -PercentComplete (($processed / $files.Count) * 100)
    
    $outputFile = Join-Path $OutputPath $file.Name
    
    # Create subdirectory structure if recursive
    if ($Recursive) {
        $relativePath = $file.FullName.Substring((Get-Item $Path).FullName.Length).TrimStart('\')
        $outputFile = Join-Path $OutputPath $relativePath
        $outputDir = Split-Path $outputFile
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
    }
    
    $originalSize = $file.Length
    
    Write-Host "$($file.Name) " -NoNewline -ForegroundColor White
    Write-Host "(" -NoNewline -ForegroundColor Gray
    Write-Host (Format-FileSize -Size $originalSize) -NoNewline -ForegroundColor Gray
    Write-Host ")" -ForegroundColor Gray
    
    if (Optimize-Image -InputPath $file.FullName -OutputPath $outputFile -Quality $Quality -MaxSize $Resize -Format $OutputFormat) {
        $newSize = (Get-Item $outputFile).Length
        $saved = $originalSize - $newSize
        $percent = [Math]::Round((($saved / $originalSize) * 100), 1)
        
        $totalSaved += $saved
        $successCount++
        
        Write-Host "  → " -NoNewline -ForegroundColor Green
        Write-Host (Format-FileSize -Size $newSize) -NoNewline -ForegroundColor Green
        Write-Host " (saved " -NoNewline -ForegroundColor Gray
        Write-Host "$percent%" -NoNewline -ForegroundColor Yellow
        Write-Host ")" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ Failed" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Progress -Activity "Optimizing images" -Completed

# Summary
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Summary" -ForegroundColor Green -NoNewline
Write-Host "                               ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""

Write-Host "Processed: " -NoNewline
Write-Host "$successCount / $($files.Count) images" -ForegroundColor Green

Write-Host "Total saved: " -NoNewline
Write-Host (Format-FileSize -Size $totalSaved) -ForegroundColor Yellow

$avgSaved = if ($files.Count -gt 0) { [Math]::Round(($totalSaved / ($files | Measure-Object -Property Length -Sum).Sum) * 100, 1) } else { 0 }
Write-Host "Average reduction: " -NoNewline
Write-Host "$avgSaved%" -ForegroundColor Yellow

Write-Host ""
Write-Host "✓ Optimization complete!" -ForegroundColor Green
Write-Host "Optimized images saved to: $OutputPath" -ForegroundColor Cyan
Write-Host ""

