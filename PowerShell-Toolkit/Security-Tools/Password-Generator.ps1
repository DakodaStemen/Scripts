#Requires -Version 5.1

<#
.SYNOPSIS
    Advanced password generator with strength checker
.DESCRIPTION
    Generate secure passwords with customizable rules and check password strength
.PARAMETER Length
    Password length (default: 16)
.PARAMETER Count
    Number of passwords to generate (default: 1)
.PARAMETER IncludeSymbols
    Include special symbols
.PARAMETER NoAmbiguous
    Exclude ambiguous characters (0, O, l, 1, etc.)
.PARAMETER CheckStrength
    Check strength of provided password
.PARAMETER Passphrase
    Generate passphrase instead of password
.EXAMPLE
    .\Password-Generator.ps1 -Length 20 -Count 5 -IncludeSymbols
.EXAMPLE
    .\Password-Generator.ps1 -CheckStrength "MyPassword123!"
.NOTES
    Author: PowerShell Toolkit
    Uses cryptographically secure random generation
#>

param(
    [int]$Length = 16,
    [int]$Count = 1,
    [switch]$IncludeSymbols,
    [switch]$NoAmbiguous,
    [string]$CheckStrength,
    [switch]$Passphrase
)

$uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
$lowercase = "abcdefghijklmnopqrstuvwxyz"
$numbers = "0123456789"
$symbols = "!@#$%^&*()-_=+[]{}|;:,.<>?"
$ambiguous = "0O1lI"

$wordlist = @(
    "alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel",
    "india", "juliet", "kilo", "lima", "mike", "november", "oscar", "papa",
    "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey",
    "xray", "yankee", "zulu", "tiger", "eagle", "phoenix", "dragon", "wolf"
)

function Get-SecureRandom {
    param([int]$Max)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $bytes = New-Object byte[] 4
    $rng.GetBytes($bytes)
    $value = [BitConverter]::ToInt32($bytes, 0)
    [Math]::Abs($value) % $Max
}

function New-Password {
    param([int]$Length, [bool]$UseSymbols, [bool]$ExcludeAmbiguous)
    
    $chars = $uppercase + $lowercase + $numbers
    if ($UseSymbols) { $chars += $symbols }
    
    if ($ExcludeAmbiguous) {
        foreach ($char in $ambiguous.ToCharArray()) {
            $chars = $chars.Replace($char, '')
        }
    }
    
    $password = ""
    
    # Ensure at least one of each required type
    $password += $uppercase[(Get-SecureRandom -Max $uppercase.Length)]
    $password += $lowercase[(Get-SecureRandom -Max $lowercase.Length)]
    $password += $numbers[(Get-SecureRandom -Max $numbers.Length)]
    if ($UseSymbols) {
        $password += $symbols[(Get-SecureRandom -Max $symbols.Length)]
    }
    
    # Fill remaining length
    $remaining = $Length - $password.Length
    for ($i = 0; $i -lt $remaining; $i++) {
        $password += $chars[(Get-SecureRandom -Max $chars.Length)]
    }
    
    # Shuffle the password
    $passwordArray = $password.ToCharArray()
    for ($i = $passwordArray.Length - 1; $i -gt 0; $i--) {
        $j = Get-SecureRandom -Max ($i + 1)
        $temp = $passwordArray[$i]
        $passwordArray[$i] = $passwordArray[$j]
        $passwordArray[$j] = $temp
    }
    
    return -join $passwordArray
}

function New-Passphrase {
    param([int]$WordCount = 4)
    
    $words = @()
    for ($i = 0; $i -lt $WordCount; $i++) {
        $word = $wordlist[(Get-SecureRandom -Max $wordlist.Count)]
        $words += $word.Substring(0,1).ToUpper() + $word.Substring(1)
    }
    
    $separator = @('-', '_', '.', '+')[(Get-SecureRandom -Max 4)]
    $number = Get-SecureRandom -Max 100
    
    return ($words -join $separator) + $separator + $number
}

function Test-PasswordStrength {
    param([string]$Password)
    
    $score = 0
    $feedback = @()
    
    # Length check
    if ($Password.Length -ge 8) { $score += 1 }
    if ($Password.Length -ge 12) { $score += 1 }
    if ($Password.Length -ge 16) { $score += 1 }
    
    # Character variety
    if ($Password -cmatch '[a-z]') { $score += 1; $feedback += "✓ Lowercase letters" }
    if ($Password -cmatch '[A-Z]') { $score += 1; $feedback += "✓ Uppercase letters" }
    if ($Password -match '\d') { $score += 1; $feedback += "✓ Numbers" }
    if ($Password -match '[!@#$%^&*(),.?":{}|<>]') { $score += 2; $feedback += "✓ Special symbols" }
    
    # Complexity
    if ($Password.Length -ge 12 -and ($Password -cmatch '[a-z]' -and $Password -cmatch '[A-Z]' -and $Password -match '\d')) {
        $score += 2
    }
    
    # Penalties
    if ($Password -match '(.)\1{2,}') { $score -= 1; $feedback += "⚠ Repeated characters" }
    if ($Password -match '(012|123|234|345|456|567|678|789|890)') { $score -= 1; $feedback += "⚠ Sequential numbers" }
    if ($Password -match '(abc|bcd|cde|def|efg|fgh)') { $score -= 1; $feedback += "⚠ Sequential letters" }
    
    # Common passwords check (simplified)
    $common = @("password", "123456", "qwerty", "admin", "letmein", "welcome")
    foreach ($word in $common) {
        if ($Password -match $word) { $score -= 3; $feedback += "✗ Contains common word: $word"; break }
    }
    
    # Rating
    $rating = switch ($score) {
        {$_ -le 3} { @{Text="Very Weak"; Color="Red"} }
        {$_ -le 5} { @{Text="Weak"; Color="Yellow"} }
        {$_ -le 7} { @{Text="Fair"; Color="Yellow"} }
        {$_ -le 9} { @{Text="Good"; Color="Green"} }
        default { @{Text="Excellent"; Color="Green"} }
    }
    
    return @{
        Score = $score
        Rating = $rating.Text
        Color = $rating.Color
        Feedback = $feedback
        Length = $Password.Length
        Entropy = [Math]::Round($Password.Length * [Math]::Log($Password.Length) / [Math]::Log(2), 2)
    }
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      Password Generator & Strength Checker" -ForegroundColor Cyan -NoNewline
Write-Host "       ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if ($CheckStrength) {
    # Check password strength
    Write-Host "Analyzing password strength..." -ForegroundColor Cyan
    Write-Host ""
    
    $result = Test-PasswordStrength -Password $CheckStrength
    
    Write-Host "Password: " -NoNewline
    Write-Host $CheckStrength -ForegroundColor White
    Write-Host "Length: " -NoNewline
    Write-Host "$($result.Length) characters" -ForegroundColor Gray
    Write-Host "Entropy: " -NoNewline
    Write-Host "$($result.Entropy) bits" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "Strength: " -NoNewline
    Write-Host $result.Rating -ForegroundColor $result.Color
    Write-Host "Score: " -NoNewline
    Write-Host "$($result.Score)/12" -ForegroundColor $(if ($result.Score -ge 8) { "Green" } else { "Yellow" })
    Write-Host ""
    
    if ($result.Feedback.Count -gt 0) {
        Write-Host "Analysis:" -ForegroundColor Cyan
        foreach ($item in $result.Feedback) {
            Write-Host "  $item" -ForegroundColor White
        }
    }
    
    # Time to crack estimate (simplified)
    $combinations = [Math]::Pow(94, $result.Length)
    $guessesPerSecond = 1000000000 # 1 billion guesses per second
    $secondsToCrack = $combinations / $guessesPerSecond
    
    $timeEstimate = if ($secondsToCrack -gt 31536000000) {
        "Millions of years"
    } elseif ($secondsToCrack -gt 31536000) {
        "$([Math]::Round($secondsToCrack / 31536000)) years"
    } elseif ($secondsToCrack -gt 86400) {
        "$([Math]::Round($secondsToCrack / 86400)) days"
    } elseif ($secondsToCrack -gt 3600) {
        "$([Math]::Round($secondsToCrack / 3600)) hours"
    } else {
        "Less than an hour"
    }
    
    Write-Host "`nEstimated time to crack: " -NoNewline
    Write-Host $timeEstimate -ForegroundColor $(if ($secondsToCrack -gt 31536000) { "Green" } else { "Red" })
    
} elseif ($Passphrase) {
    # Generate passphrases
    Write-Host "Generating secure passphrases..." -ForegroundColor Cyan
    Write-Host ""
    
    for ($i = 1; $i -le $Count; $i++) {
        $pass = New-Passphrase -WordCount 4
        Write-Host "$i. " -NoNewline -ForegroundColor Gray
        Write-Host $pass -ForegroundColor Green
        
        # Show strength
        $strength = Test-PasswordStrength -Password $pass
        Write-Host "   Strength: " -NoNewline -ForegroundColor Gray
        Write-Host $strength.Rating -NoNewline -ForegroundColor $strength.Color
        Write-Host " ($($strength.Score)/12)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "Passphrases are easier to remember and type!" -ForegroundColor Yellow
    
} else {
    # Generate passwords
    Write-Host "Generating secure passwords..." -ForegroundColor Cyan
    Write-Host "Length: " -NoNewline
    Write-Host "$Length characters" -ForegroundColor Yellow
    Write-Host "Symbols: " -NoNewline
    Write-Host $(if ($IncludeSymbols) { "Yes" } else { "No" }) -ForegroundColor Yellow
    Write-Host "Ambiguous: " -NoNewline
    Write-Host $(if ($NoAmbiguous) { "Excluded" } else { "Included" }) -ForegroundColor Yellow
    Write-Host ""
    
    for ($i = 1; $i -le $Count; $i++) {
        $password = New-Password -Length $Length -UseSymbols $IncludeSymbols -ExcludeAmbiguous $NoAmbiguous
        
        Write-Host "$i. " -NoNewline -ForegroundColor Gray
        Write-Host $password -ForegroundColor Green
        
        # Show strength
        $strength = Test-PasswordStrength -Password $password
        Write-Host "   Strength: " -NoNewline -ForegroundColor Gray
        Write-Host $strength.Rating -NoNewline -ForegroundColor $strength.Color
        Write-Host " ($($strength.Score)/12)" -ForegroundColor Gray
        Write-Host ""
    }
}

Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              Security Tips" -ForegroundColor Green -NoNewline
Write-Host "                          ║" -ForegroundColor Green
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "✓ Use different passwords for each account" -ForegroundColor White
Write-Host "✓ Enable 2FA whenever possible" -ForegroundColor White
Write-Host "✓ Use a password manager" -ForegroundColor White
Write-Host "✓ Change passwords regularly" -ForegroundColor White
Write-Host "✓ Never share passwords" -ForegroundColor White
Write-Host ""

