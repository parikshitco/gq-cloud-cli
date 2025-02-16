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
}

function Install-AWS {
    Write-Host "Installing AWS CLI..."
    
    try {
        $msiFile = Join-Path $env:TEMP "AWSCLIV2.msi"
        $installerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"

        if (Get-Command aws -ErrorAction SilentlyContinue) {
            Write-Host "AWS CLI is already installed:"
            aws --version
            $configure = Read-Host "Would you like to reconfigure AWS? (y/N)"
            if ($configure -ne "y") {
                return
            }
        }
        else {
            Invoke-WebRequest -Uri $installerUrl -OutFile $msiFile
            Start-Process msiexec.exe -Args "/i $msiFile /quiet" -Wait
            Remove-Item $msiFile -Force
        }

        Write-Host "`nConfiguring AWS CLI..."
        $accessKey = Read-Host "AWS Access Key ID"
        $secretKey = Read-Host "AWS Secret Access Key"
        $region = Read-Host "Default region (e.g., us-east-1)"

        aws configure set aws_access_key_id $accessKey
        aws configure set aws_secret_access_key $secretKey
        aws configure set region $region
        aws configure set output json

        Write-Host "Successfully configured AWS CLI!"
        aws sts get-caller-identity
    }
    catch {
        Write-Host "Error: $_" -ForegroundColor Red
        exit 1
    }
}

function Uninstall-AWS {
    Write-Host "Uninstalling AWS CLI..."
    
    try {
        $app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "AWS Command Line Interface*" }
        if ($app) {
            $app.Uninstall()
            Remove-Item -Path "$env:USERPROFILE\.aws" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Successfully removed AWS CLI!"
        }
        else {
            Write-Host "AWS CLI is not installed."
        }
    }
    catch {
        Write-Host "Error uninstalling AWS CLI: $_" -ForegroundColor Red
        exit 1
    }
}

function Configure-VM {
    try {
        $sshPath = "$env:USERPROFILE\.ssh"
        if (-not (Test-Path $sshPath)) {
            New-Item -ItemType Directory -Path $sshPath | Out-Null
        }

        $configPath = Join-Path $sshPath "config"
        if (-not (Test-Path $configPath)) {
            New-Item -ItemType File -Path $configPath | Out-Null
        }

        Write-Host "`nConfiguring SSH Client..."
        $vmName = Read-Host "Enter VM name (e.g., dev-server)"
        $ipAddress = Read-Host "Enter IP address"
        $keyPath = Read-Host "Enter path to SSH key"

        if ([string]::IsNullOrWhiteSpace($vmName) -or 
            [string]::IsNullOrWhiteSpace($ipAddress) -or 
            [string]::IsNullOrWhiteSpace($keyPath)) {
            Write-Host "Error: All fields are required" -ForegroundColor Red
            exit 1
        }

        $keyPath = $keyPath.Replace("~", $env:USERPROFILE)
        if (-not (Test-Path $keyPath)) {
            Write-Host "Error: SSH key not found at $keyPath" -ForegroundColor Red
            exit 1
        }

        $config = @"
# Configuration for $vmName
Host $vmName
        HostName $ipAddress
        IdentityFile $keyPath
        User gqadmin

"@

        Add-Content -Path $configPath -Value $config
        Write-Host "Successfully configured SSH!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error configuring VM: $_" -ForegroundColor Red
        exit 1
    }
}

function Manage-VM {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet("start", "stop", "restart")]
        [string]$Action
    )
    
    try {
        Write-Host "`n${Action}ing EC2 Instance..."
        $instanceId = Read-Host "Enter Instance ID (e.g., i-0123456789abcdef0)"

        if ($instanceId -notmatch '^i-[a-zA-Z0-9]+$') {
            Write-Host "Error: Invalid instance ID format" -ForegroundColor Red
            exit 1
        }

        # Verify instance exists
        try {
            $null = aws ec2 describe-instances --instance-ids $instanceId
        }
        catch {
            Write-Host "Error: Instance not found" -ForegroundColor Red
            exit 1
        }

        switch ($Action) {
            "start" {
                aws ec2 start-instances --instance-ids $instanceId --output json
                Write-Host "Waiting for instance to start..."
                aws ec2 wait instance-running --instance-ids $instanceId
            }
            "stop" {
                aws ec2 stop-instances --instance-ids $instanceId --output json
                Write-Host "Waiting for instance to stop..."
                aws ec2 wait instance-stopped --instance-ids $instanceId
            }
            "restart" {
                aws ec2 reboot-instances --instance-ids $instanceId --output json
                Start-Sleep -Seconds 10
                Write-Host "Waiting for instance to restart..."
                aws ec2 wait instance-running --instance-ids $instanceId
            }
        }

        Write-Host "Successfully completed $Action operation!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error managing VM: $_" -ForegroundColor Red
        exit 1
    }
}

# Main script execution
try {
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
            Show-Usage
            exit 1
        }
    }
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
    exit 1
}