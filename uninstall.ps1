# Windows Uninstall Script for GQ Cloud CLI and AWS CLI

# Ensure the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: This script needs to be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

Write-Host "GQ Cloud Management Tool and AWS CLI Uninstallation" -ForegroundColor Blue
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
Write-Host "Checking for AWS CLI installation..." -ForegroundColor Blue
$awsCliInstalled = Get-Command aws -ErrorAction SilentlyContinue

if ($awsCliInstalled) {
    Write-Host "Uninstalling AWS CLI..." -ForegroundColor Blue
    try {
        # AWS CLI Uninstallation Command (works for MSI installation)
        $awsUninstall = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -match "AWS CLI" }
        if ($awsUninstall) {
            $awsUninstall.Uninstall()
            Write-Host "AWS CLI has been successfully uninstalled." -ForegroundColor Green
        }
        else {
            Write-Host "AWS CLI not found in installed programs." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error: Failed to uninstall AWS CLI" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
        $success = $false
    }
}
else {
    Write-Host "AWS CLI is not installed on this system." -ForegroundColor Yellow
}

# Verify removal
$remainingFiles = $filesToRemove | Where-Object { Test-Path $_ }
if ($remainingFiles.Count -eq 0 -and $success) {
    Write-Host "`nGQ Cloud CLI and AWS CLI have been successfully uninstalled!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nWarning: Some components could not be removed. Please check manually." -ForegroundColor Yellow
    $remainingFiles | ForEach-Object { Write-Host "- $_" }
    exit 1
}
