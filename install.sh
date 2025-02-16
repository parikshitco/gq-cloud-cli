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

cleanup_old_installation() {
    # Remove any existing installations
    sudo rm -f /usr/local/bin/gq-cloud
    rm -f ~/bin/gq-cloud
    sudo rm -f /usr/bin/gq-cloud
    
    # Clear hash table for the command
    hash -r 2>/dev/null || true
}

if [ "$OS" = "Linux" ]; then
    echo -e "\n${BLUE}Installing for Linux...${RESET_COLOR}"
    
    # Cleanup old installation first
    echo "Cleaning up any existing installation..."
    cleanup_old_installation
    
    # Create temporary directory
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Download the Linux script
    echo "Downloading gq-cloud script..."
    if curl -fsSL "$REPO_URL/$LINUX_SCRIPT" -o "gq-cloud"; then
        chmod +x gq-cloud
        
        # Install to /usr/local/bin
        echo "Installing gq-cloud to /usr/local/bin..."
        if sudo mv gq-cloud /usr/local/bin/gq-cloud; then
            # Clear hash table to update command location
            hash -r 2>/dev/null || true
            
            # Verify installation
            if command -v gq-cloud >/dev/null 2>&1; then
                echo -e "${GREEN}✓ Successfully installed gq-cloud to /usr/local/bin/gq-cloud${RESET_COLOR}"
                echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
                echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
            else
                echo -e "${RED}✗ Installation succeeded but command not found in PATH${RESET_COLOR}"
                echo -e "Please try: ${YELLOW}sudo ln -sf /usr/local/bin/gq-cloud /usr/bin/gq-cloud${RESET_COLOR}"
                rm -rf "$TEMP_DIR"
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
    # Windows installation code remains the same...
    echo -e "\n${BLUE}Installing for Windows...${RESET_COLOR}"
    # ... rest of Windows installation ...

else
    echo -e "${RED}Error: Unsupported operating system${RESET_COLOR}"
    exit 1
fi

exit 0