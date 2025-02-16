# Windows Uninstall Script for GQ Cloud CLI

Write-Host "GQ Cloud Management Tool Uninstallation" -ForegroundColor Blue
Write-Host "----------------------------------------"

# Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Error: This script needs to be run as Administrator" -ForegroundColor Red
    Write-Host "Please right-click on PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Array of files to remove
$filesToRemove = @(
    "C:\Windows\System32\gq-cloud.ps1",
    "C:\Windows\System32\gq-cloud.bat"
)

$success = $true

foreach ($file in $filesToRemove) {
    Write-Host "Removing $file..." -ForegroundColor Blue
    if (Test-Path $file) {
        try {
            Remove-Item -Path $file -Force
            Write-Host "Successfully removed $file" -ForegroundColor Green
        }
        catch {
            Write-Host "Failed to remove $file: $_" -ForegroundColor Red
            $success = $false
        }
    }
    else {
        Write-Host "File not found: $file" -ForegroundColor Yellow
    }
}

# Clear PowerShell command path cache
try {
    Get-Command gq-cloud -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    [System.Environment]::SetEnvironmentVariable("Path", [System.Environment]::GetEnvironmentVariable("Path", "Machine"), "Machine")
}
catch {
    # Ignore any errors from command cache clearing
}

if ($success) {
    Write-Host "`nGQ Cloud CLI has been successfully uninstalled!" -ForegroundColor Green
}
else {
    Write-Host "`nSome components could not be removed. Please try running the script again as Administrator." -ForegroundColor Yellow
}

# Verify removal
$verifyFiles = $filesToRemove | Where-Object { Test-Path $_ }
if ($verifyFiles.Count -eq 0) {
    Write-Host "All GQ Cloud CLI files have been removed from your system." -ForegroundColor Green
}
else {
    Write-Host "Warning: The following files could not be removed:" -ForegroundColor Yellow
    $verifyFiles | ForEach-Object { Write-Host "- $_" }
}