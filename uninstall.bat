@echo off
setlocal

ver > nul
if not errorlevel 1 (
    rem Windows detected
    echo Running Windows uninstallation...
    powershell.exe -ExecutionPolicy Bypass -Command "& { iwr -useb https://raw.githubusercontent.com/parikshitco/gq-cloud-cli/main/uninstall.ps1 | iex }"
) else (
    rem Linux detected
    echo Running Linux uninstallation...
    bash -c "curl -fsSL https://raw.githubusercontent.com/parikshitco/gq-cloud-cli/main/uninstall.sh | bash"
)

endlocal
