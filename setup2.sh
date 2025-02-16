#!/bin/bash
set -e

# Colors for output
RESET_COLOR="\033[0m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"

echo -e "${BLUE}GQ Cloud Management Tool Setup${RESET_COLOR}"
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
    echo -e "\n${BLUE}Setting up Linux environment...${RESET_COLOR}"
    
    # Make the current gq-cloud script executable
    chmod +x "$(pwd)/gq-cloud"
    
    # Create symlink in /usr/local/bin
    echo "Adding gq-cloud to /usr/local/bin..."
    if sudo ln -sf "$(pwd)/gq-cloud" /usr/local/bin/gq-cloud; then
        echo -e "${GREEN}✓ Successfully added gq-cloud to /usr/local/bin/gq-cloud${RESET_COLOR}"
        echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
        echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
    else
        echo -e "${RED}✗ Failed to add gq-cloud${RESET_COLOR}"
        exit 1
    fi
elif [ "$OS" = "Windows" ]; then
    echo -e "\n${BLUE}Setting up Windows environment...${RESET_COLOR}"
    
    # Copy the script to Windows PATH
    WIN_INSTALL_DIR="/c/Windows/System32"
    if cp "$(pwd)/gq-cloud.ps1" "$WIN_INSTALL_DIR/gq-cloud.ps1"; then
        echo -e "${GREEN}✓ Successfully installed gq-cloud${RESET_COLOR}"
        echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
        echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
    else
        echo -e "${RED}✗ Failed to install gq-cloud${RESET_COLOR}"
        exit 1
    fi
else
    echo -e "${RED}Error: Unsupported operating system${RESET_COLOR}"
    exit 1
fi

exit 0
