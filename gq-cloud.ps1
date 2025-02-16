[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$Operation
)

# Output formatting (Using ForegroundColor instead of ANSI)
function Write-ColorMessage {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Show-Usage {
    Write-ColorMessage "`nUsage: gq-cloud <operation>`n" "Cyan"

    Write-ColorMessage "AWS Operations:" "Yellow"
    Write-ColorMessage "    -aws, --aws-setup      Setup AWS environment" "White"
    Write-ColorMessage "    -raws, --remove-aws    Remove AWS environment`n" "White"

    Write-ColorMessage "VM Operations:" "Yellow"
    Write-ColorMessage "    -vm, --vm-setup        Setup VM environment" "White"
    Write-ColorMessage "    -vms, --vm-start       Start VM environment" "White"
    Write-ColorMessage "    -vmd, --vm-stop        Stop VM environment" "White"
    Write-ColorMessage "    -vmr, --vm-restart     Restart VM environment`n" "White"

    Write-ColorMessage "Help:" "Yellow"
    Write-ColorMessage "    -h, --help             Show this help message" "White"
}

# Ensure required functions exist
function Install-AWS {
    Write-ColorMessage "Setting up AWS environment..." "Green"
    # Add AWS setup logic here
}

function Uninstall-AWS {
    Write-ColorMessage "Removing AWS environment..." "Green"
    # Add AWS removal logic here
}

function Configure-VM {
    Write-ColorMessage "Configuring VM environment..." "Green"
    # Add VM setup logic here
}

function Manage-VM {
    param([string]$Action)
    switch ($Action) {
        "start" { Write-ColorMessage "Starting VM..." "Green" }
        "stop" { Write-ColorMessage "Stopping VM..." "Red" }
        "restart" { Write-ColorMessage "Restarting VM..." "Yellow" }
        default { Write-ColorMessage "Unknown VM action: $Action" "Red" }
    }
}

# Main script execution
try {
    # Handle empty input or help flags
    if ([string]::IsNullOrWhiteSpace($Operation) -or 
        $Operation -match "^(--help|-help|-h|help)$") {
        Show-Usage
        exit 0
    }

    switch -Regex ($Operation.ToLower()) {  # Case-insensitive matching
        '^(-aws|--aws-setup)$' { Install-AWS; break }
        '^(-raws|--remove-aws)$' { Uninstall-AWS; break }
        '^(-vm|--vm-setup)$' { Configure-VM; break }
        '^(-vms|--vm-start)$' { Manage-VM -Action "start"; break }
        '^(-vmd|--vm-stop)$' { Manage-VM -Action "stop"; break }
        '^(-vmr|--vm-restart)$' { Manage-VM -Action "restart"; break }
        default {
            Write-ColorMessage "Error: Unknown operation '$Operation'" "Red"
            Show-Usage
            exit 1
        }
    }
}
catch {
    Write-ColorMessage "Error: $_" "Red"
    exit 1
}
