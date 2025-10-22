# PowerShell Toolkit - Professional Automation Scripts

A comprehensive collection of production-ready PowerShell scripts for system management, development automation, and productivity enhancement.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)

## 📦 What's Inside

### 🔧 System Utilities (5 scripts)
- **PC-Health-Check** - Weekly system health monitoring and optimization
- **Auto-Backup** - Automated backup with compression and scheduling
- **System-Info** - Beautiful system information dashboard
- **Windows-Update-Manager** - Check, download, and install Windows updates
- **Environment-Manager** - Manage environment variables with ease

### 💻 Development Tools (2 scripts)
- **Git-Auto-Commit** - Automated git operations with smart commit messages
- **Project-Initializer** - Quick project scaffolding for multiple frameworks

### 📁 File Management (4 scripts)
- **Smart-File-Organizer** - Intelligent file organization by type/date
- **Duplicate-Finder** - Find and remove duplicate files with MD5 hashing
- **Batch-Renamer** - Powerful batch file renaming with patterns
- **Large-File-Finder** - Identify space-consuming files quickly

### 🌐 Network Tools (2 scripts)
- **Speed-Test** - Internet speed testing with logging
- **Port-Scanner** - Network port scanner with service detection

### ⚡ Productivity (4 scripts)
- **Clipboard-Manager** - Clipboard history with search and restore
- **Screenshot-Organizer** - Auto-organize and rename screenshots
- **Quick-Notes** - Fast note-taking from command line
- **Process-Manager** - Interactive process viewer and killer

### 🎨 Web & Portfolio (3 scripts)
- **Image-Optimizer** - Compress images for web (up to 80% size reduction)
- **Deploy-To-Cloudflare** - One-click Cloudflare Pages deployment

### 🔒 **Security Tools** (2 scripts) ⭐ NEW!
- **Password-Generator** - Advanced password generation with strength checking
- **WiFi-Manager** - WiFi profile management and password recovery

**Total: 27 Professional Scripts Across 7 Categories**

---

## 🚀 Quick Start

### One-Line Install (Recommended)
```powershell
# Run as Administrator
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DakodaStemen/Scripts/main/PowerShell-Toolkit/Install.ps1'))
```

### Manual Installation
1. Clone or download this repository
2. Open PowerShell as Administrator
3. Navigate to the toolkit directory
4. Run the installer:
```powershell
.\Install.ps1
```

---

## 📖 Usage

### Quick Start Launcher
```powershell
# Use the convenient health check launcher
.\Quick-Health-Check.ps1           # Standard check
.\Quick-Health-Check.ps1 -Detailed # Comprehensive analysis
.\Quick-Health-Check.ps1 -Quick    # Fast overview
```

### Individual Scripts
Each script has detailed help documentation:

```powershell
# View help for any script
Get-Help .\ScriptName.ps1 -Full

# Example usage
.\System-Utilities\PC-Health-Check.ps1
.\Development-Tools\Project-Initializer.ps1 -ProjectType React -Name MyApp
.\File-Management\Smart-File-Organizer.ps1 -Path "C:\Downloads"
```

---

## 🎯 Features

✅ **Professional Quality** - Production-ready, well-tested code  
✅ **Fully Documented** - Comprehensive help and examples  
✅ **Error Handling** - Robust error handling and logging  
✅ **Cross-Version** - Works with PowerShell 5.1+  
✅ **Modular Design** - Use scripts independently or together  
✅ **No Dependencies** - Pure PowerShell, no external tools required  

---

## 📋 Requirements

- **OS**: Windows 10/11 or Windows Server 2016+
- **PowerShell**: 5.1 or later
- **Privileges**: Some scripts require Administrator rights
- **Execution Policy**: RemoteSigned or Unrestricted

### Set Execution Policy
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🛠️ Configuration

Most scripts can be configured via:
1. **Command-line parameters** - For one-time use
2. **Config files** - For persistent settings (JSON)
3. **Environment variables** - For system-wide defaults

---

## 📊 Script Categories

| Category | Scripts | Use Cases |
|----------|---------|-----------|
| 🔧 System Utilities | 4 | System maintenance, monitoring, optimization |
| 💻 Development | 4 | Project setup, version control, code analysis |
| 📁 File Management | 4 | Organization, cleanup, batch operations |
| 🌐 Network | 4 | Connectivity, diagnostics, monitoring |
| ⚡ Productivity | 4 | Personal workflow, time management |
| 🎨 Web/Portfolio | 4 | Web development, deployment, optimization |

---

## 🤝 Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add your script with documentation
4. Submit a pull request

---

## 📜 License

MIT License - Feel free to use in personal or commercial projects.

---

## 💡 Tips

- **Start with**: PC-Health-Check and Smart-File-Organizer
- **For developers**: Git-Auto-Commit and Project-Initializer
- **For web devs**: Image-Optimizer and Deploy-To-Cloudflare
- **Power users**: Try Clipboard-Manager and Time-Tracker

---

## 🔗 Links

- **GitHub**: [github.com/DakodaStemen/Scripts](https://github.com/DakodaStemen/Scripts)
- **Portfolio**: [dakoda.co](https://dakoda.co)
- **Issues**: [Report bugs or request features](https://github.com/DakodaStemen/Scripts/issues)

---

## 📞 Support

- 📧 Email: contact@dakoda.co
- � LinkedIn: [linkedin.com/in/dakodastemen](https://linkedin.com/in/dakodastemen)
- 🌐 Portfolio: [dakoda.co](https://dakoda.co)

---

**Made with ❤️ for the PowerShell community**

