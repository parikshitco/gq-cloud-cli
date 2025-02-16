param(
    [switch]$init,
    [switch]$re,
    [switch]$vm,
    [switch]$vms,
    [switch]$vmd,
    [switch]$vmr,
    [switch]$h
)

# AWS Functions
function Install-AWS {
    Write-Host "Setting up environment..."
    
    $msiFile = Join-Path $env:TEMP "AWSCLIV2.msi"
    $installerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"

    # Check if AWS CLI is already installed
    if (Get-Command aws -ErrorAction SilentlyContinue) {
        Write-Host "Environment is already installed:"
        aws --version
        $configure = Read-Host "Would you like to reconfigure environment? (y/N)"
        if ($configure -ne "y") {
            return
        }
    }
    else {
        Write-Host "Downloading installer..."
        Invoke-WebRequest -Uri $installerUrl -OutFile $msiFile
        
        Write-Host "Installing..."
        Start-Process msiexec.exe -Args "/i $msiFile /quiet" -Wait
        Remove-Item $msiFile -Force

        # Wait a few seconds to ensure installation completes
        Start-Sleep -Seconds 5

        # Force PowerShell to reload environment variables without restarting
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" +
                    [System.Environment]::GetEnvironmentVariable("Path", "User")

        # Verify AWS CLI installation
        Write-Host "Verifying installation..."
        aws --version
    }

    Write-Host "`nConfiguring..."
    $accessKey = Read-Host "Access Key ID"
    # To use SecureString for secret key, uncomment the following line
    # $secretKey = Read-Host -AsSecureString "AWS Secret Access Key"
    $secretKey = Read-Host "Secret Access Key"
    # $region = Read-Host "Default region (e.g., us-east-1)"

    if ([string]::IsNullOrWhiteSpace($accessKey) -or 
        [string]::IsNullOrWhiteSpace([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey))) -or 
        [string]::IsNullOrWhiteSpace($region)) {
        throw "Access key, secret key, and region are required"
    }

    # Configure AWS CLI
    aws configure set aws_access_key_id $accessKey
    aws configure set aws_secret_access_key ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($secretKey)))
    aws configure set region $region
    aws configure set region eu-west-2
    aws configure set output json

    # Verify configuration
    # try {
    $verifyConfig = aws sts get-caller-identity 2>&1
    if ($verifyConfig -match "error" -or [string]::IsNullOrWhiteSpace($verifyConfig)) {
        Write-Host "Failed to verify configuration"
    }
    else {
        Write-Host ("`nEnvironment configured successfully!") -ForegroundColor Green
    }


} # Closing brace for Install-AWS function

function Uninstall-AWS {
    Write-Host "Removing environment..."

    try {
        # Get installed AWS CLI
        $awsApp = Get-WmiObject Win32_Product | Where-Object { $_.Name -like "AWS Command Line Interface*" }
        
        if ($awsApp) {
            Write-Host "Uninstalling..."
            Start-Process msiexec.exe -ArgumentList "/x $($awsApp.IdentifyingNumber) /quiet /norestart" -Wait

            # Remove AWS credentials and config
            if (Test-Path "$env:USERPROFILE\.aws") {
                Remove-Item "$env:USERPROFILE\.aws" -Recurse -Force
            }

            Write-Host "Environment has been successfully removed!" -ForegroundColor Green
        }
        else {
            Write-Host "Environment dosen't exist."
        }
    }
    catch {
        Write-Host "Error removing : $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}


# VM Functions
function Configure-VM {
    Write-Host "Configuring VM environment..."
    try {
            # Create .ssh directory if it doesn't exist
            $sshPath = "$env:USERPROFILE\.ssh"
            if (-not (Test-Path $sshPath)) {
                New-Item -ItemType Directory -Path $sshPath | Out-Null
            }

            # Create or check config file
            $configPath = Join-Path $sshPath "config"
            if (-not (Test-Path $configPath)) {
                New-Item -ItemType File -Path $configPath | Out-Null
            }

            # Get configuration details
            Write-Host "`nConfiguring SSH Client..."
            $vmName = Read-Host "Enter VM name (e.g., dev-server)"
            $ipAddress = Read-Host "Enter IP address"
            $keyPath = Read-Host "Enter path to SSH key"

            # Validate inputs
            if ([string]::IsNullOrWhiteSpace($vmName) -or 
                [string]::IsNullOrWhiteSpace($ipAddress) -or 
                [string]::IsNullOrWhiteSpace($keyPath)) {
                throw "All fields are required"
            }

            # Expand key path if using ~
            $keyPath = $keyPath.Replace("~", $env:USERPROFILE)

            # Verify key file exists
            if (-not (Test-Path $keyPath)) {
                throw "SSH key not found at $keyPath"
            }

            # Check if host already exists
            $configContent = Get-Content $configPath -Raw
            if ($configContent -match "Host\s+$vmName") {
                $updateHost = Read-Host "Host '$vmName' already exists. Update it? (y/N)"
                if ($updateHost -ne "y") {
                    Write-Host "Keeping existing configuration"
                    return
                }
                # Create backup and remove existing host
                Copy-Item $configPath "$configPath.backup"
                $configContent = $configContent -replace "(?ms)Host\s+$vmName.*?(?=Host|\z)", ""
                Set-Content $configPath $configContent
            }

            # Add new configuration
            $newConfig = @"

# Configuration for $vmName
Host $vmName
        HostName $ipAddress
        IdentityFile $keyPath
        User gqadmin

"@
            Add-Content $configPath $newConfig

            Write-Host "`nSSH configuration added successfully!" -ForegroundColor Green
            Write-Host "You can now connect using: ssh $vmName"
        }
        catch {
            Write-Host "Error configuring VM: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
}

function Manage-VM {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("start", "stop", "restart")]
        [string]$Action
    )
     try {
            Write-Host "`n${Action}ing VM..."
            $instanceId = Read-Host "Enter Instance ID (e.g i-0123456789abcdef0)"
            if (-not $instanceId -or $instanceId -notmatch '^i-[a-zA-Z0-9]+$') {
                Write-Host "Invalid instance ID format. Please enter a valid ID." -ForegroundColor Red
                exit 1
            }
            if ($instanceId -notmatch '^i-[a-zA-Z0-9]+$') {
                throw "Invalid instance ID format"
            }

            # Verify instance exists before proceeding
            $instanceData = aws ec2 describe-instances --instance-ids $instanceId | ConvertFrom-Json
            if (-not $instanceData.Reservations) {
                throw "Instance not found or invalid permissions"
            }

            # Write-Host "Managing instance $instanceId..."
            switch ($Action) {
                "start" {
                    aws ec2 start-instances --instance-ids $instanceId | Out-Null
                    Write-Host "Waiting for VM to start..."
                    
                    Start-Sleep -Seconds 5  # Initial wait
                    
                    # Loop to check instance state
                    while ($true) {
                        $state = aws ec2 describe-instances --instance-ids $instanceId --query 'Reservations[*].Instances[*].State.Name' --output text
                        # Write-Host "Current State: $state"

                        if ($state -eq "running") {
                            Write-Host "VM is now running!" -ForegroundColor Green
                            break
                        }

                        Start-Sleep -Seconds 5  # Wait before checking again
                    }
                }
                "stop" {
                    Write-Host "Stopping VM $instanceId..."
                    aws ec2 stop-instances --instance-ids $instanceId | Out-Null

                    Write-Host "Waiting for VM to stop..."
                    Start-Sleep -Seconds 5  # Initial wait to allow the stop process to begin

                    # Poll the instance state every 5 seconds for up to 1 minute
                    $maxAttempts = 6  # 12 attempts (12 * 5s = 60s)
                    $attempt = 0
                    do {
                        $currentState = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text
                        # Write-Host "Current instance state: $currentState"
                        
                        if ($currentState -eq "stopped") {
                            Write-Host "VM is now stopped." -ForegroundColor Green
                            break
                        }

                        Start-Sleep -Seconds 5
                        $attempt++
                    } while ($attempt -lt $maxAttempts)

                    if ($currentState -ne "stopped") {
                        Write-Host "⚠️ VM did not stop within the expected time." -ForegroundColor Yellow
                    }
                }
                "restart" {
                    $currentState = aws ec2 describe-instances --instance-ids $instanceId --query "Reservations[*].Instances[*].State.Name" --output text
                    
                    if ($currentState -eq "stopped") {
                        Write-Host "VM is stopped. Starting it instead of rebooting..."
                        aws ec2 start-instances --instance-ids $instanceId | Out-Null
                        Write-Host "Waiting for VM to start..."
                        aws ec2 wait instance-running --instance-ids $instanceId
                    } elseif ($currentState -eq "running") {
                        Write-Host "Rebooting VM..."
                        aws ec2 reboot-instances --instance-ids $instanceId | Out-Null
                        Write-Host "Waiting for VM to restart..."
                        Start-Sleep -Seconds 10
                        aws ec2 wait instance-running --instance-ids $instanceId
                    } else {
                        Write-Host "⚠️ VM is in an unknown state: $currentState. Cannot restart." -ForegroundColor Yellow
                    }
                }

            }

            Write-Host "VM $Action completed successfully!" -ForegroundColor Green
        }
        catch {
            Write-Host "Error managing VM: $($_.Exception.Message)" -ForegroundColor Red
            exit 1
        }
}

# Command Processing
try {
    if ($h) {
        Write-Host "`nUsage: gq-cloud (operation)`n"
        Write-Host "VM Operations:"
        Write-Host "  -init     Setup environment"
        Write-Host "  -re    Remove environment"
        Write-Host "VM Operations:"
        Write-Host "  -vm      Setup VM environment"
        Write-Host "  -vms     Start VM"
        Write-Host "  -vmd     Stop VM"
        Write-Host "  -vmr     Restart VM"

        Write-Host "Help:"
        Write-Host "  -h       Show this help message"
        exit 0
    }

    if ($init) { Install-AWS; exit 0 }
    if ($re) { Uninstall-AWS; exit 0 }
    if ($vm) { Configure-VM; exit 0 }
    if ($vms) { Manage-VM -Action "start"; exit 0 }
    if ($vmd) { Manage-VM -Action "stop"; exit 0 }
    if ($vmr) { Manage-VM -Action "restart"; exit 0 }

    # If no valid parameter is provided, show help
    Write-Host "`nError: $($_.Exception.Message)`n" -ForegroundColor Red
    Write-Host "Use -h for help" -ForegroundColor Yellow
    exit 1
}
catch {
    $errorMessage = $_.Exception.Message
    Write-Host "`nError: $errorMessage `n" -ForegroundColor Red
    exit 1
}

