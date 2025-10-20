# Weekly PC Performance Optimizer & Health Check

Automated PowerShell script to keep your PC running at **FULL SPEED & FULL FORCE** - detecting slowdowns, cleaning junk, and ensuring maximum performance.

## Features

### 🚀 **Performance Optimization** (NEW!)
- **CPU usage tracking** - Detect performance bottlenecks
- **Temperature monitoring** - Prevent thermal throttling
- **Resource hog detection** - Identify top CPU/Memory consumers
- **Disk health monitoring (SMART)** - Catch failing drives before slowdowns
- **Memory optimization** - Detect memory leaks
- **Startup impact analysis** - Identify programs slowing boot time
- **Automatic cleanup** - Remove temp files, clear caches, empty recycle bin

### 🛡️ **Security Checks**
- Windows Defender status verification
- Real-time protection status
- Antivirus signature updates
- Active threat detection
- Firewall status verification
- Automatic Quick Scan initiation

### 💻 **System Health**
- Memory usage monitoring with optimization
- Disk space checks for all drives
- Windows Update status
- Recent system errors from Event Log

### 📊 **Detailed Logging**
- Color-coded console output (Green/Yellow/Red)
- Comprehensive log files with timestamps
- Performance-focused summary reports

## Installation

### Step 1: Download the Scripts
Place both `WeeklyPCCheck.ps1` and `Setup-WeeklyTask.ps1` in the same folder (e.g., `C:\Projects\Scripts`).

### Step 2: Set Up the Scheduled Task

1. **Open PowerShell as Administrator**
   - Press `Win + X`
   - Select "Windows PowerShell (Admin)" or "Terminal (Admin)"

2. **Navigate to the script folder**
   ```powershell
   cd C:\Projects\Scripts
   ```

3. **Run the setup script**
   ```powershell
   .\Setup-WeeklyTask.ps1
   ```

This will create a scheduled task that runs every Sunday at 10:00 AM.

## Manual Testing

To test the script immediately without waiting for the scheduled run:

```powershell
# Run as Administrator
.\WeeklyPCCheck.ps1
```

## Viewing Logs

All check results are saved in the `Logs` subfolder with timestamps:
- Location: `C:\Projects\Scripts\Logs\`
- Format: `PCCheck_YYYY-MM-DD_HHMMSS.log`

## Customization

### Change the Schedule

To modify when the check runs:

1. Open Task Scheduler (`Win + R`, type `taskschd.msc`)
2. Find "Weekly PC Health Check" in the task list
3. Right-click and select "Properties"
4. Go to the "Triggers" tab
5. Edit the trigger to your preferred schedule

### Modify What Gets Checked

Edit `WeeklyPCCheck.ps1` and comment out or add functions in the main execution section at the bottom of the script.

## What the Script Checks & Optimizes

| Check | Optimal | Warning | Critical |
|-------|---------|---------|----------|
| CPU Usage | < 80% | 80-95% | > 95% |
| Memory Usage | < 85% | 85-95% | > 95% |
| Temperature | < 70°C | 70-85°C | > 85°C |
| Disk Space | > 15% free | 5-15% free | < 5% free |
| Disk Health | Healthy | Warning | Unhealthy |
| AV Signatures | < 2 days old | 2-7 days | > 7 days |
| Startup Items | < 10 items | 10-15 items | > 15 items |

### Automatic Actions Performed:
- ✅ Cleans Windows Temp folder
- ✅ Cleans User Temp folder  
- ✅ Empties Recycle Bin
- ✅ Runs Windows Disk Cleanup
- ✅ Identifies resource-hogging processes
- ✅ Detects memory leaks
- ✅ Monitors disk health to prevent failures
- ✅ Analyzes startup impact for faster boot

## Troubleshooting

### "Execution policy" errors
If you get execution policy errors, run PowerShell as Administrator and execute:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Script doesn't run on schedule
- Ensure the script is in a location that exists and hasn't been moved
- Check Task Scheduler for any error messages
- Verify the task is enabled
- Check that the task has proper permissions

### Permission errors
The script requires Administrator privileges to:
- Check Windows Defender status
- Start security scans
- Access system event logs
- Check firewall settings

## Uninstalling

To remove the scheduled task:

```powershell
Unregister-ScheduledTask -TaskName "Weekly PC Health Check" -Confirm:$false
```

Or open Task Scheduler and manually delete the task.

## Requirements

- Windows 10 or later
- PowerShell 5.1 or later
- Administrator privileges
- Windows Defender (for security checks)

## Log Output Example

```
[2025-10-19 10:00:00] [INFO] Starting Weekly PC Performance & Health Check
[2025-10-19 10:00:01] [SUCCESS] CPU Usage: 12.5% - Running at full speed
[2025-10-19 10:00:01] [SUCCESS] Memory Usage: 64.2% (9.87 GB / 15.37 GB) - Optimal
[2025-10-19 10:00:02] [SUCCESS] Temperature: 45.2C (113.4F) - Optimal cooling
[2025-10-19 10:00:03] [INFO] Top CPU consumers: Chrome (125s), System (45s)
[2025-10-19 10:00:04] [SUCCESS] Disk: Samsung SSD 970 (1000GB) - Health: HEALTHY
[2025-10-19 10:00:04] [SUCCESS] No memory leaks detected
[2025-10-19 10:00:05] [SUCCESS] Cleaned Windows Temp folder - 2.3 GB freed
[2025-10-19 10:00:05] [SUCCESS] Total space freed: 2.3 GB - Performance boost!
[2025-10-19 10:00:06] [SUCCESS] Windows Defender: Enabled
[2025-10-19 10:00:06] [SUCCESS] Active Threats: None detected
[2025-10-19 10:00:07] [SUCCESS] ====== PC RUNNING AT FULL SPEED & FULL FORCE! ======
```

## License

Free to use and modify for personal or commercial use.

