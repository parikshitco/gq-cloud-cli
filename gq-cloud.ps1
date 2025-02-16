param(
    [Parameter(Position=0)]
    [string]$Operation
)

# Output colors
$Colors = @{
    Reset = "`e[0m"
    Blue = "`e[1;34m"
    Green = "`e[1;32m"
    Red = "`e[0;31m"
    Yellow = "`e[0;33m"
}

function Show-Usage {
    Write-Host "Usage: .\gq-cloud.ps1 <operation>"
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
    
    $msiFile = "$env:TEMP\AWSCLIV2.msi"
    $installerUrl = "https://awscli.amazonaws.com/AWSCLIV2.msi"

    try {
        if (Get-Command aws -ErrorAction SilentlyContinue) {
            Write-Host "AWS CLI is already installed:"
            aws --version
            $configure = Read-Host "Would you like to reconfigure AWS? (y/N)"
            if ($configure -ne "y") {
                return
            }
        } else {
            Invoke-WebRequest -Uri $installerUrl -OutFile $msiFile
            Start-Process msiexec.exe -Args "/i $msiFile /quiet" -Wait
            Remove-Item $msiFile
        }

        Write-Host "`nConfiguring AWS CLI..."
        $accessKey = Read-Host "AWS Access Key ID"
        $secretKey = Read-Host "AWS Secret Access Key"
        $region = Read-Host "Default region (e.g., us-east-1)"

        aws configure set aws_access_key_id $accessKey
        aws configure set aws_secret_access_key $secretKey
        aws configure set region $region
        aws configure set output json

        Write-Host "✓ AWS CLI configured successfully!"
        aws sts get-caller-identity
    }
    catch {
        Write-Host "✗ Error: $_"
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
            Write-Host "✓ AWS CLI has been successfully removed!"
        } else {
            Write-Host "AWS CLI is not installed."
        }
    }
    catch {
        Write-Host "✗ Error uninstalling AWS CLI: $_"
        exit 1
    }
}

function Configure-VM {
    $sshPath = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshPath)) {
        New-Item -ItemType Directory -Path $sshPath | Out-Null
    }

    $configPath = "$sshPath\config"
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
        Write-Host "Error: All fields are required"
        exit 1
    }

    $keyPath = $keyPath.Replace("~", $env:USERPROFILE)
    if (-not (Test-Path $keyPath)) {
        Write-Host "Error: SSH key not found at $keyPath"
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
    Write-Host "✓ SSH configuration added successfully!"
}

function Manage-VM {
    param($Action)
    
    Write-Host "`n${Action}ing EC2 Instance..."
    $instanceId = Read-Host "Enter Instance ID (e.g., i-0123456789abcdef0)"

    if ($instanceId -notmatch '^i-[a-zA-Z0-9]+$') {
        Write-Host "Error: Invalid instance ID format"
        exit 1
    }

    try {
        aws ec2 describe-instances --instance-ids $instanceId | Out-Null

        switch ($Action) {
            "start" {
                aws ec2 start-instances --instance-ids $instanceId | Out-Null
                Write-Host "Waiting for instance to start..."
                aws ec2 wait instance-running --instance-ids $instanceId
            }
            "stop" {
                aws ec2 stop-instances --instance-ids $instanceId | Out-Null
                Write-Host "Waiting for instance to stop..."
                aws ec2 wait instance-stopped --instance-ids $instanceId
            }
            "restart" {
                aws ec2 reboot-instances --instance-ids $instanceId | Out-Null
                Start-Sleep -Seconds 10
                Write-Host "Waiting for instance to restart..."
                aws ec2 wait instance-running --instance-ids $instanceId
            }
        }
        Write-Host "✓ Instance $Action completed successfully"
    }
    catch {
        Write-Host "✗ Error managing instance: $_"
        exit 1
    }
}

# Main script execution
switch ($Operation) {
    { $_ -in "-aws","--aws-setup" } {
        Install-AWS
        break
    }
    { $_ -in "-raws","--remove-aws" } {
        Uninstall-AWS
        break
    }
    { $_ -in "-vm","--vm-setup" } {
        Configure-VM
        break
    }
    { $_ -in "-vms","--vm-start" } {
        Manage-VM -Action "start"
        break
    }
    { $_ -in "-vmd","--vm-stop" } {
        Manage-VM -Action "stop"
        break
    }
    { $_ -in "-vmr","--vm-restart" } {
        Manage-VM -Action "restart"
        break
    }
    default {
        Show-Usage
        exit 1
    }
}
