# Windows Uninstall Script for GQ Cloud CLI and AWS CLI

# Ensure the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: This script needs to be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "GQ Cloud Management Tool" -ForegroundColor Blue
Write-Host "-----------------------------------------------------"

# Define files to remove
$filesToRemove = @(
    "$env:SystemRoot\System32\gq-cloud.ps1",
    "$env:SystemRoot\System32\gq-cloud.bat"
)

$success = $true

# Remove GQ Cloud CLI files
foreach ($file in $filesToRemove) {
    if (Test-Path $file) {
        try {
            Write-Host "Removing $file..." -ForegroundColor Blue
            Remove-Item -Path $file -Force -ErrorAction Stop
            Write-Host "Successfully removed $file" -ForegroundColor Green
        }
        catch {
            Write-Host "Error: Failed to remove $file" -ForegroundColor Red
            Write-Host $_.Exception.Message -ForegroundColor Red
            $success = $false
        }
    }
    else {
        Write-Host "File not found: $file" -ForegroundColor Yellow
    }
}

# Remove GQ Cloud CLI from PATH if necessary
try {
    $EnvPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") -split ";" 
    $UpdatedPath = $EnvPath -notmatch "gq-cloud"
    if ($UpdatedPath -ne $EnvPath) {
        [System.Environment]::SetEnvironmentVariable("Path", ($UpdatedPath -join ";"), "Machine")
        Write-Host "Removed GQ Cloud from system PATH" -ForegroundColor Green
    }
}
catch {
    Write-Host "Warning: Failed to update system PATH" -ForegroundColor Yellow
}

# Uninstall AWS CLI
Write-Host "Checking for environment installation..." -ForegroundColor Blue

try {
    # Find AWS CLI installation in Programs and Features
    $awsApp = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*AWS Command Line Interface*" }
    
    if ($awsApp) {
        Write-Host "Found environment installation: $($awsApp.Name)" -ForegroundColor Blue
        
        # Kill any running AWS processes
        Get-Process | Where-Object { $_.Name -like "*aws*" } | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        
        # Uninstall using msiexec with elevated privileges
        $process = Start-Process msiexec.exe -ArgumentList "/x $($awsApp.IdentifyingNumber) /qn" -Wait -NoNewWindow -PassThru
        Start-Sleep -Seconds 10  # Wait for uninstallation to complete
        
        # Remove AWS directory using cmd.exe with elevated privileges
        $awsPath = "C:\Program Files\Amazon\AWSCLIV2"
        if (Test-Path $awsPath) {
            Write-Host "Removing directory using elevated cmd..." -ForegroundColor Blue
            $cmdArgs = "/c rd /s /q `"$awsPath`""
            Start-Process cmd.exe -ArgumentList $cmdArgs -Verb RunAs -Wait
        }
        
        # Remove .aws directory from user profile
        $awsConfigPath = "$env:USERPROFILE\.aws"
        if (Test-Path $awsConfigPath) {
            Remove-Item -Path $awsConfigPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        
        Write-Host "Uninstallation completed." -ForegroundColor Green
    } else {
        Write-Host "Installation not found in Programs and Features." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error during environment uninstallation: $_" -ForegroundColor Red
    $success = $false
}

# Verify removal
$remainingFiles = $filesToRemove | Where-Object { Test-Path $_ }
if ($remainingFiles.Count -eq 0 -and $success) {
    Write-Host "`nGQ Cloud CLI have been successfully uninstalled!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nWarning: Some components could not be removed. Please check manually." -ForegroundColor Yellow
    $remainingFiles | ForEach-Object { Write-Host "- $_" }
    exit 1
}
