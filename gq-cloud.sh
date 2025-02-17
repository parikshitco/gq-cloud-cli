#!/bin/bash

# Colors for output
RESET_COLOR="\033[0m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"

usage() {
    echo "Usage: gq-cloud <operation>"
    echo ""
    echo "VM Operations:"
    echo "    -init, --env-setup     Setup environment"
    echo "    -re,   --remove-env    Remove environment"
    echo "    -vm,   --vm-setup      Setup VM environment"
    echo "    -vms,  --vm-start      Start VM"
    echo "    -vmd,  --vm-stop       Stop VM"
    echo "    -vmr,  --vm-restart    Restart VM"
}

install_and_configure_aws() {
    # Check if AWS CLI is already installed
    if command -v aws &> /dev/null; then
        echo "Environment is already up:"
        aws --version
    else
        echo "Setting up environment..."
        
        # Create and move to temporary directory
        TEMP_DIR="$HOME/aws-cli-temp"
        mkdir -p "$TEMP_DIR" || { echo "Error: Failed to create temporary directory"; exit 1; }
        cd "$TEMP_DIR" || { echo "Error: Failed to change to temporary directory"; exit 1; }
        
        # Download and install AWS CLI
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" || {
            echo "Error: Failed to download installer"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Install unzip if not present
        if ! command -v unzip &> /dev/null; then
            echo "Installing unzip..."
            sudo apt-get update && sudo apt-get install -y unzip || {
                echo "Error: Failed to install unzip"
                rm -rf "$TEMP_DIR"
                exit 1
            }
        fi
        
        unzip -q awscliv2.zip
        sudo ./aws/install --update
        
        cd "$HOME"
        rm -rf "$TEMP_DIR"
        
        if ! aws --version; then
            echo "✗ Installation failed"
            exit 1
        fi
        echo "✓ Installed successfully!"
    fi

    # AWS Configuration
    if [[ -f ~/.aws/credentials ]] && aws sts get-caller-identity &> /dev/null; then
        echo -e "\nExisting configuration found and verified:"
        aws sts get-caller-identity
        read -p "Would you like to create a new configuration? (y/N): " create_new
        if [[ ! "$create_new" =~ ^[Yy]$ ]]; then
            echo "Keeping existing configuration"
            return 0
        fi
    fi

    echo -e "\nConfiguring..."
    mkdir -p ~/.aws
    
    read -p "Access Key ID: " aws_access_key
    read -p "Secret Access Key: " aws_secret_key
    # read -p "Default region (e.g., eu-west-2): " aws_region
    
    if [[ -z "$aws_access_key" || -z "$aws_secret_key"]]; then
        echo "Error: Access key and secret key are required"
        exit 1
    fi
    
    aws configure set aws_access_key_id "$aws_access_key"
    aws configure set aws_secret_access_key "$aws_secret_key"
    aws configure set region "eu-west-2"
    aws configure set output "json"
    
    if aws sts get-caller-identity &> /dev/null; then
        echo "✓ Configured successfully!"
        aws sts get-caller-identity
    else
        echo "✗ Configuration verification failed"
        exit 1
    fi
}

uninstall_aws_cli() {
    echo "Uninstalling Environment..."
    
    sudo rm -rf /usr/local/aws-cli
    sudo rm -f /usr/local/bin/aws
    sudo rm -f /usr/local/bin/aws_completer
    rm -rf ~/.aws
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get remove -y awscli
        sudo apt-get autoremove -y
    elif command -v yum &> /dev/null; then
        sudo yum remove -y awscli
    fi
    
    if ! command -v aws &> /dev/null; then
        echo "✓ Environment has been successfully removed!"
    else
        echo "✗ Environment removal may have been incomplete"
        echo "Manual removal may be required for: $(which aws)"
        exit 1
    fi
}

configure_vm() {
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    if [[ ! -f ~/.ssh/config ]]; then
        touch ~/.ssh/config
        chmod 600 ~/.ssh/config
    fi

    echo -e "\nConfiguring SSH Client..."
    read -p "Enter VM name (e.g., dev-server): " vm_name
    read -p "Enter IP address: " ip_address
    read -p "Enter path to SSH key (e.g., ~/.ssh/id_rsa): " key_path

    if [[ -z "$vm_name" || -z "$ip_address" || -z "$key_path" ]]; then
        echo "Error: All fields are required"
        exit 1
    fi

    key_path="${key_path/#\~/$HOME}"

    if [[ ! -f "$key_path" ]]; then
        echo "Error: SSH key not found at $key_path"
        exit 1
    fi

    chmod 600 "$key_path"

    if grep -q "^Host $vm_name$" ~/.ssh/config; then
        echo "Warning: Host '$vm_name' already exists in config"
        read -p "Would you like to update it? (y/N): " update_host
        if [[ ! "$update_host" =~ ^[Yy]$ ]]; then
            echo "Keeping existing configuration"
            return 0
        fi
        cp ~/.ssh/config ~/.ssh/config.backup
        sed -i "/^Host $vm_name$/,/^$/d" ~/.ssh/config
    fi

    {
        echo -e "\n# Configuration for $vm_name"
        echo "Host $vm_name"
        echo "        HostName $ip_address"
        echo "        IdentityFile $key_path"
        echo "        User gqadmin"
        echo ""
    } >> ~/.ssh/config

    chmod 600 ~/.ssh/config

    echo "✓ SSH configuration added successfully!"
    echo "✓ SSH key permissions set to 600"
    echo -e "\nYou can now connect using:"
    echo "ssh $vm_name"
}

manage_vm() {
    local action=$1
    echo -e "\n${action^}ing VM..."
    
    read -p "Enter Instance ID (e.g., i-0123456789abcdef0): " instance_id
    
    if [[ ! "$instance_id" =~ ^i-[a-zA-Z0-9]+$ ]]; then
        echo "Error: Invalid instance ID format"
        exit 1
    fi
    
    if ! aws ec2 describe-instances --instance-ids "$instance_id" &> /dev/null; then
        echo "Error: Instance not found"
        exit 1
    fi
    
    case "$action" in
        "start")
            aws ec2 start-instances --instance-ids "$instance_id" &> /dev/null && 
            aws ec2 wait instance-running --instance-ids "$instance_id"
            ;;
        "stop")
            aws ec2 stop-instances --instance-ids "$instance_id" &> /dev/null &&
            aws ec2 wait instance-stopped --instance-ids "$instance_id"
            ;;
        "restart")
            aws ec2 reboot-instances --instance-ids "$instance_id" &> /dev/null
            sleep 10
            aws ec2 wait instance-running --instance-ids "$instance_id"
            ;;
    esac

    if [ $? -eq 0 ]; then
        echo "✓ Vm ${action} successful"
    else
        echo "✗ Failed to ${action} VM"
        exit 1
    fi
}

# Main script execution
case "$1" in
    -init|--env-setup)
        install_and_configure_aws
        ;;
    -re|--remove-env)
        uninstall_aws_cli
        ;;
    -vm|--vm-setup)
        configure_vm
        ;;
    -vms|--vm-start)
        manage_vm "start"
        ;;
    -vmd|--vm-stop)
        manage_vm "stop"
        ;;
    -vmr|--vm-restart)
        manage_vm "restart"
        ;;
    *)
        usage
        exit 1
        ;;
esac

exit 0
