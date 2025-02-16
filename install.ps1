# Windows Installation Script for GQ Cloud CLI

# Repository details
$RepoUrl = "https://raw.githubusercontent.com/parikshitco/gq-cloud-cli/refs/heads/main"
$ScriptName = "gq-cloud.ps1"

Write-Host "GQ Cloud Management Tool Installation" -ForegroundColor Blue
Write-Host "----------------------------------------"

# Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: This script needs to be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Create temporary directory
$TempDir = Join-Path $env:TEMP "gq-cloud-install"
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

try {
    # Remove any existing installations
    Write-Host "`nRemoving any existing installations..." -ForegroundColor Blue
    if (Test-Path "C:\Windows\System32\gq-cloud.ps1") {
        Remove-Item "C:\Windows\System32\gq-cloud.ps1" -Force
    }
    if (Test-Path "C:\Windows\System32\gq-cloud.bat") {
        Remove-Item "C:\Windows\System32\gq-cloud.bat" -Force
    }

    # Download the script
    Write-Host "Downloading gq-cloud script..." -ForegroundColor Blue
    $WebClient = New-Object System.Net.WebClient
    $ScriptUrl = "$RepoUrl/$ScriptName"
    $ScriptPath = Join-Path $TempDir "gq-cloud.ps1"
    
    try {
        $WebClient.DownloadFile($ScriptUrl, $ScriptPath)
    }
    catch {
        Write-Host "✗ Failed to download script: $_" -ForegroundColor Red
        exit 1
    }

    # Install the script
    Write-Host "Installing gq-cloud..." -ForegroundColor Blue
    
    try {
        # Copy PowerShell script
        Copy-Item $ScriptPath -Destination "C:\Windows\System32\gq-cloud.ps1" -Force
        
        # Create BAT wrapper
        $BatContent = @"
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0gq-cloud.ps1" %*
"@
        $BatContent | Set-Content "C:\Windows\System32\gq-cloud.bat" -Force

        # Verify installation
        if (Test-Path "C:\Windows\System32\gq-cloud.ps1") {
            Write-Host "✓ Successfully installed gq-cloud" -ForegroundColor Green
            Write-Host "You can now use the" -NoNewline
            Write-Host " gq-cloud " -ForegroundColor Blue -NoNewline
            Write-Host "command from Command Prompt or PowerShell"
            Write-Host "Try" -NoNewline
            Write-Host " gq-cloud --help " -ForegroundColor Yellow -NoNewline
            Write-Host "to get started"
        }
        else {
            throw "Installation verification failed"
        }
    }
    catch {
        Write-Host "✗ Failed to install: $_" -ForegroundColor Red
        exit 1
    }
}
finally {
    # Cleanup
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
}