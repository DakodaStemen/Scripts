# Contributing to PowerShell Scripts Collection

Thank you for your interest in contributing to this PowerShell scripts collection! This document provides guidelines for contributing to make the process smooth and consistent.

## 🤝 How to Contribute

### 1. Fork & Clone
```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR-USERNAME/Scripts.git
cd Scripts
```

### 2. Create a Branch
```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

### 3. Make Changes
- Follow the coding standards below
- Add proper documentation
- Test your scripts thoroughly

### 4. Submit Pull Request
- Push to your fork
- Create a pull request with clear description
- Reference any related issues

## 📝 Script Standards

### PowerShell Script Requirements

#### 1. **Header Documentation**
Every script must include comprehensive help documentation:

```powershell
<#
.SYNOPSIS
    Brief description of what the script does

.DESCRIPTION
    Detailed description of the script's functionality, use cases, and behavior

.PARAMETER ParameterName
    Description of each parameter

.EXAMPLE
    Example of how to use the script
    PS> .\YourScript.ps1 -Parameter Value

.NOTES
    Author: Your Name
    Version: 1.0
    Created: YYYY-MM-DD
    Last Modified: YYYY-MM-DD
    Requires: PowerShell 5.1+
    
.LINK
    https://github.com/DakodaStemen/Scripts
#>
```

#### 2. **Parameter Validation**
```powershell
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Description of parameter")]
    [ValidateNotNullOrEmpty()]
    [string]$RequiredParameter,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Option1", "Option2", "Option3")]
    [string]$OptionalParameter = "Option1"
)
```

#### 3. **Error Handling**
```powershell
try {
    # Main script logic
}
catch {
    Write-Error "Error occurred: $($_.Exception.Message)"
    exit 1
}
finally {
    # Cleanup code
}
```

#### 4. **Logging**
```powershell
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "INFO" { "Green" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
        }
    )
}
```

### 📁 File Organization

#### Directory Structure
```
PowerShell-Toolkit/
├── Category-Name/
│   ├── Script-Name.ps1
│   └── README.md (category-specific)
├── README.md
└── Install.ps1
```

#### Naming Conventions
- **Scripts**: `Pascal-Case-With-Hyphens.ps1`
- **Categories**: `Pascal-Case-With-Hyphens/`
- **Variables**: `$PascalCase` for script-level, `$camelCase` for local
- **Functions**: `Verb-Noun` following PowerShell conventions

## 🎯 Categories

When adding scripts, place them in the appropriate category:

- **System-Utilities**: System maintenance, monitoring, configuration
- **Development-Tools**: Development workflow automation, git helpers
- **File-Management**: File operations, organization, cleanup
- **Network-Tools**: Network diagnostics, connectivity testing
- **Productivity**: Personal productivity, time management, utilities
- **Web-Portfolio**: Web development, deployment, optimization
- **Security-Tools**: Security utilities, password management

## ✅ Testing Guidelines

### Before Submitting
1. **Test on clean PowerShell session**
2. **Verify with different PowerShell versions** (5.1+)
3. **Test error conditions** and edge cases
4. **Run with `-WhatIf`** parameter if applicable
5. **Verify help documentation** with `Get-Help .\Script.ps1 -Full`

### Test Checklist
- [ ] Script runs without errors
- [ ] All parameters work as expected
- [ ] Error handling catches exceptions properly
- [ ] Help documentation is complete and accurate
- [ ] Script follows naming conventions
- [ ] No hardcoded paths (use parameters/variables)
- [ ] Appropriate output verbosity levels
- [ ] Clean exit codes (0 for success, 1+ for errors)

## 📋 Code Style

### PowerShell Best Practices
```powershell
# Use approved verbs
Get-SystemInfo    # ✅ Good
Fetch-SystemInfo  # ❌ Bad

# Use full parameter names in scripts
Get-ChildItem -Path $Directory -Recurse    # ✅ Good
gci $Directory -r                          # ❌ Bad (aliases)

# Use proper indentation (4 spaces)
if ($condition) {
    Write-Host "Properly indented"
    if ($nestedCondition) {
        Write-Host "Nested properly"
    }
}

# Use meaningful variable names
$UserDocumentsPath    # ✅ Good
$udp                  # ❌ Bad
```

### Comment Standards
```powershell
# Main section headers
# ==========================================
# MAIN SCRIPT LOGIC
# ==========================================

# Function descriptions
# Gets system information and formats output
function Get-SystemInfo {

# Inline comments for complex logic
# Calculate percentage (avoid division by zero)
$percentage = if ($total -gt 0) { ($current / $total) * 100 } else { 0 }
```

## 🐛 Bug Reports

### Issue Template
When reporting bugs, include:
1. **PowerShell version** (`$PSVersionTable`)
2. **Windows version** and edition
3. **Complete error message** (if any)
4. **Steps to reproduce**
5. **Expected vs actual behavior**
6. **Script parameters used**

## 💡 Feature Requests

### Suggestion Guidelines
- **Clear use case**: Explain why the feature is useful
- **Specific requirements**: Detail what the feature should do
- **Compatibility**: Consider impact on existing functionality
- **Category fit**: Suggest appropriate category placement

## 🏆 Recognition

Contributors will be:
- Listed in the main README.md
- Credited in individual scripts they create/modify
- Given appropriate GitHub repository permissions for regular contributors

## 📞 Questions?

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Email**: contact@dakoda.co for direct communication

---

**Thank you for helping make this PowerShell collection better for everyone!** 🚀