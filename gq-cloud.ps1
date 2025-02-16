[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Operation
)

# Output formatting
$Colors = @{
    ResetColor = "`e[0m"
    Blue = "`e[1;34m"
    Green = "`e[1;32m"
    Red = "`e[0;31m"
    Yellow = "`e[0;33m"
}

function Show-Usage {
    Write-Host "Usage: gq-cloud <operation>"
    Write-Host ""
    Write-Host "AWS Operations:"
    Write-Host "    -aws, --aws-setup      Setup AWS environment"
    Write-Host "    -raws, --remove-aws    Remove AWS environment"
    Write-Host ""
    Write-Host "VM Operations:"
    Write-Host "    -vm, --vm-setup        Setup VM environment"
    Write-Host "    -vms, --vm-start       Start VM environment"
    Write-Host "    -vmd, --vm-stop        Stop VM environment"
    Write-Host "    -vmr, --vm-restart     Restart VM environment"
    Write-Host ""
    Write-Host "Help:"
    Write-Host "    -h, --help             Show this help message"
}

# ... [rest of your functions remain the same] ...

# Main script execution
try {
    # Handle empty input or help flags
    if ([string]::IsNullOrWhiteSpace($Operation) -or 
        $Operation -eq "-h" -or 
        $Operation -eq "--help" -or 
        $Operation -eq "-help" -or 
        $Operation -eq "help") {
        Show-Usage
        exit 0
    }

    switch -Regex ($Operation) {
        '^(-aws|--aws-setup)$' {
            Install-AWS
            break
        }
        '^(-raws|--remove-aws)$' {
            Uninstall-AWS
            break
        }
        '^(-vm|--vm-setup)$' {
            Configure-VM
            break
        }
        '^(-vms|--vm-start)$' {
            Manage-VM -Action "start"
            break
        }
        '^(-vmd|--vm-stop)$' {
            Manage-VM -Action "stop"
            break
        }
        '^(-vmr|--vm-restart)$' {
            Manage-VM -Action "restart"
            break
        }
        default {
            Write-Host "Error: Unknown operation '$Operation'" -ForegroundColor Red
            Show-Usage
            exit 1
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}