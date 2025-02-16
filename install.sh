#!/bin/bash
set -e

# Colors for output
RESET_COLOR="\033[0m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"

# GitHub repository details
REPO_URL="https://raw.githubusercontent.com/parikshitco/gq-cloud-cli/refs/heads/main"
LINUX_SCRIPT="gq-cloud.sh"
WINDOWS_SCRIPT="gq-cloud.ps1"

echo -e "${BLUE}GQ Cloud Management Tool Installation${RESET_COLOR}"
echo "----------------------------------------"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     OS=Linux;;
    CYGWIN*|MINGW*|MSYS*)    OS=Windows;;
    *)          OS="UNKNOWN";;
esac

echo -e "Detected OS: ${YELLOW}$OS${RESET_COLOR}"

if [ "$OS" = "Linux" ]; then
    echo -e "\n${BLUE}Installing for Linux...${RESET_COLOR}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Remove any existing installations
    echo "Removing any existing installations..."
    sudo rm -f /usr/local/bin/gq-cloud
    sudo rm -f /usr/bin/gq-cloud
    rm -f ~/bin/gq-cloud 2>/dev/null || true
    
    # Clear bash path hash
    hash -r 2>/dev/null || true
    
    # Download the Linux script
    echo "Downloading gq-cloud script..."
    if curl -fsSL "$REPO_URL/$LINUX_SCRIPT" -o "gq-cloud"; then
        chmod +x gq-cloud
        
        # Install to both /usr/bin and /usr/local/bin to ensure availability
        echo "Installing gq-cloud..."
        if sudo install -m 755 gq-cloud /usr/bin/gq-cloud; then
            # Create backup in /usr/local/bin
            sudo install -m 755 gq-cloud /usr/local/bin/gq-cloud
            
            # Clear bash path hash again
            hash -r 2>/dev/null || true
            
            # Test the installation
            if command -v gq-cloud >/dev/null 2>&1 && [ -x "$(command -v gq-cloud)" ]; then
                echo -e "${GREEN}✓ Successfully installed gq-cloud${RESET_COLOR}"
                echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
                echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
                
                # Show installation location
                echo -e "\nInstalled to: $(which gq-cloud)"
            else
                echo -e "${RED}✗ Installation verification failed${RESET_COLOR}"
                exit 1
            fi
        else
            echo -e "${RED}✗ Failed to install gq-cloud${RESET_COLOR}"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        echo -e "${RED}✗ Failed to download gq-cloud script${RESET_COLOR}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"

elif [ "$OS" = "Windows" ]; then
    echo -e "\n${BLUE}Installing for Windows...${RESET_COLOR}"
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the Windows script
    echo "Downloading gq-cloud script..."
    if curl -fsSL "$REPO_URL/$WINDOWS_SCRIPT" -o "gq-cloud.ps1"; then
        # Move to Windows system directory
        if mv gq-cloud.ps1 "/c/Windows/System32/gq-cloud.ps1"; then
            # Create a .bat file for easier access
            echo '@echo off' > "/c/Windows/System32/gq-cloud.bat"
            echo 'powershell.exe -ExecutionPolicy Bypass -File "%~dp0gq-cloud.ps1" %*' >> "/c/Windows/System32/gq-cloud.bat"
            
            echo -e "${GREEN}✓ Successfully installed gq-cloud${RESET_COLOR}"
            echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
            echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
        else
            echo -e "${RED}✗ Failed to install gq-cloud${RESET_COLOR}"
            echo -e "${YELLOW}Note: Make sure you're running this script with administrator privileges${RESET_COLOR}"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
    else
        echo -e "${RED}✗ Failed to download gq-cloud script${RESET_COLOR}"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"

else
    echo -e "${RED}Error: Unsupported operating system${RESET_COLOR}"
    exit 1
fi

exit 0