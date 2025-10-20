#Requires -Version 5.1

<#
.SYNOPSIS
    Quick project scaffolding for multiple frameworks
    
.DESCRIPTION
    Creates project structure with common configurations for React, Node, Python, .NET, and more.
    Automatically initializes git, creates README, and sets up .gitignore.
    
.PARAMETER ProjectName
    Name of the project
    
.PARAMETER ProjectType
    Type of project (React, Node, Python, DotNet, Static, Vue, Angular)
    
.PARAMETER Path
    Where to create the project (default: current directory)
    
.PARAMETER GitInit
    Initialize git repository (default: true)
    
.PARAMETER InstallDependencies
    Automatically install dependencies (npm install, pip install, etc.)
    
.EXAMPLE
    .\Project-Initializer.ps1 -ProjectName "MyApp" -ProjectType React
    
.EXAMPLE
    .\Project-Initializer.ps1 -ProjectName "APIServer" -ProjectType Node -InstallDependencies
    
.NOTES
    Author: PowerShell Toolkit
    Requires: Node.js for JS projects, Python for Python projects
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("React", "Node", "Python", "DotNet", "Static", "Vue", "Angular", "Express")]
    [string]$ProjectType,
    
    [string]$Path = (Get-Location).Path,
    
    [bool]$GitInit = $true,
    
    [switch]$InstallDependencies
)

$projectPath = Join-Path $Path $ProjectName

function Write-Success { param([string]$Message) Write-Host "✓ $Message" -ForegroundColor Green }
function Write-Info { param([string]$Message) Write-Host "→ $Message" -ForegroundColor Cyan }
function Write-Error { param([string]$Message) Write-Host "✗ $Message" -ForegroundColor Red }

function New-ProjectFolder {
    Write-Info "Creating project folder: $projectPath"
    
    if (Test-Path $projectPath) {
        Write-Error "Project folder already exists!"
        exit 1
    }
    
    New-Item -ItemType Directory -Path $projectPath -Force | Out-Null
    Write-Success "Project folder created"
}

function New-GitIgnore {
    param([string]$Type)
    
    $gitignoreContent = @"
# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/
env/

# Build outputs
dist/
build/
*.dll
*.exe
bin/
obj/

# IDE
.vscode/
.idea/
*.suo
*.user
*.swp
.DS_Store

# Environment
.env
.env.local
*.log

# OS
Thumbs.db
"@

    $gitignoreContent | Out-File -FilePath (Join-Path $projectPath ".gitignore") -Encoding UTF8
    Write-Success "Created .gitignore"
}

function New-README {
    $readmeContent = @"
# $ProjectName

## Description
Project created with PowerShell Toolkit Project Initializer

## Project Type
$ProjectType

## Getting Started

### Installation
``````bash
# Install dependencies
npm install  # or appropriate command for your project type
``````

### Development
``````bash
# Run development server
npm run dev  # or appropriate command
``````

## License
MIT

## Created
$(Get-Date -Format "yyyy-MM-dd")
"@

    $readmeContent | Out-File -FilePath (Join-Path $projectPath "README.md") -Encoding UTF8
    Write-Success "Created README.md"
}

function Initialize-ReactProject {
    Write-Info "Setting up React project..."
    
    Push-Location $projectPath
    
    # Create package.json
    $packageJson = @{
        name = $ProjectName.ToLower()
        version = "1.0.0"
        private = $true
        scripts = @{
            dev = "vite"
            build = "vite build"
            preview = "vite preview"
        }
        dependencies = @{
            react = "^18.2.0"
            "react-dom" = "^18.2.0"
        }
        devDependencies = @{
            "@vitejs/plugin-react" = "^4.0.0"
            vite = "^4.3.0"
        }
    } | ConvertTo-Json -Depth 10
    
    $packageJson | Out-File -FilePath "package.json" -Encoding UTF8
    
    # Create basic React structure
    New-Item -ItemType Directory -Path "src" -Force | Out-Null
    
    $appJsx = @"
import { useState } from 'react'
import './App.css'

function App() {
  const [count, setCount] = useState(0)

  return (
    <div className="App">
      <h1>$ProjectName</h1>
      <button onClick={() => setCount(count + 1)}>
        Count: {count}
      </button>
    </div>
  )
}

export default App
"@
    $appJsx | Out-File -FilePath "src/App.jsx" -Encoding UTF8
    
    $mainJsx = @"
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
"@
    $mainJsx | Out-File -FilePath "src/main.jsx" -Encoding UTF8
    
    # Create index.html
    $indexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>$ProjectName</title>
</head>
<body>
  <div id="root"></div>
  <script type="module" src="/src/main.jsx"></script>
</body>
</html>
"@
    $indexHtml | Out-File -FilePath "index.html" -Encoding UTF8
    
    # Create vite config
    $viteConfig = @"
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
})
"@
    $viteConfig | Out-File -FilePath "vite.config.js" -Encoding UTF8
    
    Write-Success "React project structure created"
    
    if ($InstallDependencies) {
        Write-Info "Installing dependencies..."
        npm install
        Write-Success "Dependencies installed"
    }
    
    Pop-Location
}

function Initialize-NodeProject {
    Write-Info "Setting up Node.js project..."
    
    Push-Location $projectPath
    
    # Create package.json
    $packageJson = @{
        name = $ProjectName.ToLower()
        version = "1.0.0"
        description = "Node.js project"
        main = "index.js"
        scripts = @{
            start = "node index.js"
            dev = "nodemon index.js"
        }
        dependencies = @{}
        devDependencies = @{
            nodemon = "^3.0.0"
        }
    } | ConvertTo-Json -Depth 10
    
    $packageJson | Out-File -FilePath "package.json" -Encoding UTF8
    
    # Create basic index.js
    $indexJs = @"
console.log('$ProjectName - Node.js Application');

// Your code here
"@
    $indexJs | Out-File -FilePath "index.js" -Encoding UTF8
    
    Write-Success "Node.js project structure created"
    
    if ($InstallDependencies) {
        Write-Info "Installing dependencies..."
        npm install
        Write-Success "Dependencies installed"
    }
    
    Pop-Location
}

function Initialize-PythonProject {
    Write-Info "Setting up Python project..."
    
    Push-Location $projectPath
    
    # Create main.py
    $mainPy = @"
def main():
    print('$ProjectName - Python Application')
    # Your code here

if __name__ == '__main__':
    main()
"@
    $mainPy | Out-File -FilePath "main.py" -Encoding UTF8
    
    # Create requirements.txt
    "" | Out-File -FilePath "requirements.txt" -Encoding UTF8
    
    # Create virtual environment
    Write-Info "Creating virtual environment..."
    python -m venv venv
    
    Write-Success "Python project structure created"
    Write-Info "Activate venv with: .\venv\Scripts\Activate.ps1"
    
    Pop-Location
}

function Initialize-StaticProject {
    Write-Info "Setting up Static website project..."
    
    Push-Location $projectPath
    
    # Create folders
    New-Item -ItemType Directory -Path "css", "js", "images" -Force | Out-Null
    
    # Create index.html
    $indexHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$ProjectName</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <h1>$ProjectName</h1>
    <p>Welcome to your static website!</p>
    <script src="js/main.js"></script>
</body>
</html>
"@
    $indexHtml | Out-File -FilePath "index.html" -Encoding UTF8
    
    # Create CSS
    $css = @"
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: Arial, sans-serif;
    padding: 20px;
}

h1 {
    color: #333;
}
"@
    $css | Out-File -FilePath "css/style.css" -Encoding UTF8
    
    # Create JS
    "console.log('$ProjectName loaded');" | Out-File -FilePath "js/main.js" -Encoding UTF8
    
    Write-Success "Static website structure created"
    
    Pop-Location
}

# Main execution
Write-Host "`n╔═══════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Project Initializer" -ForegroundColor Cyan -NoNewline
Write-Host "              ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

New-ProjectFolder
New-GitIgnore -Type $ProjectType
New-README

# Initialize project based on type
switch ($ProjectType) {
    "React" { Initialize-ReactProject }
    "Node" { Initialize-NodeProject }
    "Express" { Initialize-NodeProject }
    "Python" { Initialize-PythonProject }
    "Static" { Initialize-StaticProject }
    default { Write-Info "Basic project structure created" }
}

# Initialize git if requested
if ($GitInit) {
    Push-Location $projectPath
    git init | Out-Null
    git add . | Out-Null
    git commit -m "Initial commit: $ProjectName project scaffolding" | Out-Null
    Write-Success "Git repository initialized"
    Pop-Location
}

Write-Host ""
Write-Success "Project '$ProjectName' created successfully!"
Write-Info "Location: $projectPath"
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  cd $ProjectName" -ForegroundColor White

switch ($ProjectType) {
    "React" { Write-Host "  npm run dev" -ForegroundColor White }
    "Node" { Write-Host "  npm start" -ForegroundColor White }
    "Python" { 
        Write-Host "  .\venv\Scripts\Activate.ps1" -ForegroundColor White
        Write-Host "  python main.py" -ForegroundColor White
    }
    "Static" { Write-Host "  Open index.html in browser" -ForegroundColor White }
}

Write-Host ""

