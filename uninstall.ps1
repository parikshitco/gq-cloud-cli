# Universal uninstall script for both Windows and Linux

# Function to uninstall on Windows
function Uninstall-Windows {
    Write-Host "Removing gq-cloud from Windows..."
    
    # Locations to clean
    $locations = @(
        "C:\Windows\System32\gq-cloud.ps1",
        "C:\Windows\System32\gq-cloud.bat"
    )
    
    foreach ($location in $locations) {
        if (Test-Path $location) {
            try {
                Remove-Item -Path $location -Force
                Write-Host "✓ Removed $location" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ Failed to remove $location. Error: $_" -ForegroundColor Red
                Write-Host "Note: You may need to run this script as Administrator" -ForegroundColor Yellow
            }
        }
    }
    
    # Verify removal
    $remaining = Get-Command gq-cloud -ErrorAction SilentlyContinue
    if ($null -eq $remaining) {
        Write-Host "✓ gq-cloud has been successfully uninstalled" -ForegroundColor Green
    }
    else {
        Write-Host "! gq-cloud is still present in: $($remaining.Source)" -ForegroundColor Yellow
    }
}

# Check if we're running in PowerShell
if ($PSVersionTable) {
    # Windows uninstallation
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script needs to be run as Administrator" -ForegroundColor Red
        Write-Host "Please right-click the script and select 'Run as Administrator'" -ForegroundColor Yellow
        exit 1
    }
    Uninstall-Windows
}
else {
    # This part won't execute in PowerShell, it's here for documentation
    Write-Host "Please run this script using PowerShell" -ForegroundColor Red
    exit 1
}
