# PowerShell Scripts Collection

A comprehensive collection of production-ready PowerShell scripts for system administration, development automation, and operational efficiency. This repository contains both a complete **PowerShell Toolkit** with 27+ enterprise-grade scripts and additional utility scripts for Windows system management.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Windows](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/en-us/windows)

## 📦 What's Inside

### 🔧 [PowerShell Toolkit](./PowerShell-Toolkit/)
**27 Professional Scripts Across 7 Categories:**

| Category | Scripts | Description |
|----------|---------|-------------|
| 🔧 **System Utilities** | 6 scripts | System monitoring, backups, updates, environment management |
| 💻 **Development Tools** | 3 scripts | Git automation, project scaffolding, code formatting |
| 📁 **File Management** | 4 scripts | Smart organization, duplicate removal, batch operations |
| 🌐 **Network Tools** | 2 scripts | Speed testing, port scanning, connectivity diagnostics |
| ⚡ **Productivity** | 5 scripts | Clipboard management, notes, time tracking, screenshots |
| 🎨 **Web Portfolio** | 3 scripts | Image optimization, Cloudflare deployment, monitoring |
| � **Security Tools** | 2 scripts | Password generation, WiFi management |

### � Additional Resources
- **Interactive web showcase** with script browser and examples
- **Professional documentation** and contribution guidelines

---

## � Quick Start

### Option 1: Complete Toolkit Installation
```powershell
# Clone the repository
git clone https://github.com/DakodaStemen/Scripts.git
cd Scripts

# Install the complete toolkit
cd PowerShell-Toolkit
.\Install.ps1
```

### Option 2: Individual Script Usage
```powershell
# Navigate to any category
cd PowerShell-Toolkit/System-Utilities

# View help for any script
Get-Help .\PC-Health-Check.ps1 -Full

# Run with parameters
.\PC-Health-Check.ps1 -Verbose
```

### Option 3: Quick Health Check
```powershell
# Use the convenient launcher script
cd PowerShell-Toolkit
.\Quick-Health-Check.ps1

# Or run the full script directly
cd System-Utilities
.\PC-Health-Check.ps1
```

---

## 📋 Featured Scripts

### 🛡️ **PC Health Check** - `System-Utilities/PC-Health-Check.ps1`
- **CPU & Memory monitoring** with real-time optimization
- **Disk health analysis** using SMART data
- **Security verification** (Windows Defender, Firewall)
- **Automated cleanup** (temp files, caches, recycle bin)
- **Performance bottleneck detection**
- **Comprehensive logging** with color-coded output

### 🔄 **Smart File Organizer** - `File-Management/Smart-File-Organizer.ps1`
- **Intelligent categorization** by file type and date
- **Duplicate detection** with MD5 hashing
- **Custom organization rules**
- **Safe processing** with undo support

### 🚀 **Project Initializer** - `Development-Tools/Project-Initializer.ps1`
- **Multi-framework support** (React, Node.js, Python, etc.)
- **Git initialization** with .gitignore templates
- **Dependency management**
- **Project structure generation**

### 🔐 **Password Generator** - `Security-Tools/Password-Generator.ps1`
- **Customizable length and complexity**
- **Strength analysis** and recommendations
- **Pronounceable password mode**
- **Bulk generation** for enterprise use

---

## 💡 Key Features

✅ **Production-Ready** - Comprehensive error handling and validation  
✅ **Zero Dependencies** - Pure PowerShell, no external tools required  
✅ **Fully Documented** - Detailed help and usage examples  
✅ **Enterprise-Grade** - Logging, security, and compliance features  
✅ **Cross-Version Compatible** - PowerShell 5.1+ support  
✅ **Modular Design** - Use scripts independently or together  

---

## 📖 Documentation

- **[PowerShell Toolkit README](./PowerShell-Toolkit/README.md)** - Complete toolkit documentation
- **[Interactive Web Browser](./index.html)** - Visual script explorer with examples
- **Individual Script Help** - Use `Get-Help .\ScriptName.ps1 -Full` for any script

---

## 🛠️ Requirements

- **OS**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: 5.1 or later
- **Privileges**: Some scripts require Administrator rights
- **Execution Policy**: RemoteSigned or Unrestricted

### Set Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 📊 Repository Statistics

- **27** Professional Scripts
- **7** Organized Categories  
- **100%** Documented with Help
- **0** External Dependencies
- **MIT** Licensed for Commercial Use

---

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add documentation and examples
4. Submit a pull request

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

---

## 📜 License

MIT License - Free for personal and commercial use. See [LICENSE](./LICENSE) for details.

---

## 🔗 Links

- **Author**: [Dakoda Stemen](https://github.com/DakodaStemen)
- **Portfolio**: [dakoda.co](https://dakoda.co)
- **Issues**: [Report bugs or request features](https://github.com/DakodaStemen/Scripts/issues)

---

## 🏆 Popular Scripts

| Script | Category | Downloads | Description |
|--------|----------|-----------|-------------|
| PC-Health-Check | System | ⭐⭐⭐⭐⭐ | Complete system monitoring & optimization |
| Smart-File-Organizer | File Management | ⭐⭐⭐⭐ | Intelligent file organization |
| Git-Auto-Commit | Development | ⭐⭐⭐⭐ | Automated git operations |
| Password-Generator | Security | ⭐⭐⭐⭐ | Secure password generation |

---

**Made with ❤️ for the PowerShell community**

