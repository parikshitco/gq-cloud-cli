#!/bin/bash

# Colors for output
RESET_COLOR="\033[0m"
BLUE="\033[1;34m"
GREEN="\033[1;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"

echo -e "${BLUE}GQ Cloud Management Tool Setup${RESET_COLOR}"
echo "----------------------------------------"

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     
            echo "Linux"
            ;;
        CYGWIN*|MINGW*|MSYS*)     
            echo "Windows"
            ;;
        *)          
            echo "Unknown"
            ;;
    esac
}

OS=$(detect_os)
echo -e "Detected OS: ${YELLOW}$OS${RESET_COLOR}"

# Function to set up Linux environment
setup_linux() {
    echo -e "\n${BLUE}Setting up Linux environment...${RESET_COLOR}"
    
    # Create installation directory
    INSTALL_DIR="$HOME/.gq-cloud"
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$HOME/bin"
    
    # Download the Linux script
    echo "Downloading Linux script..."
    curl -o "$INSTALL_DIR/gq-cloud" "https://raw.githubusercontent.com/your-repo/gq-cloud/main/gq-cloud.sh" || {
        echo -e "${RED}Failed to download gq-cloud script${RESET_COLOR}"
        exit 1
    }
    
    # Make it executable
    chmod +x "$INSTALL_DIR/gq-cloud"
    
    # Create symbolic link
    ln -sf "$INSTALL_DIR/gq-cloud" "$HOME/bin/gq-cloud"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        source "$HOME/.bashrc"
    fi
    
    # Verify installation
    if [ -x "$HOME/bin/gq-cloud" ]; then
        echo -e "${GREEN}✓ Linux installation successful!${RESET_COLOR}"
        echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
        echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
    else
        echo -e "${RED}✗ Installation failed${RESET_COLOR}"
        exit 1
    fi
}

# Function to set up Windows environment
setup_windows() {
    echo -e "\n${BLUE}Setting up Windows environment...${RESET_COLOR}"
    
    # Create installation directory
    INSTALL_DIR="$HOME/.gq-cloud"
    mkdir -p "$INSTALL_DIR"
    
    # Download the Windows PowerShell script
    echo "Downloading Windows script..."
    curl -o "$INSTALL_DIR/gq-cloud.ps1" "https://raw.githubusercontent.com/your-repo/gq-cloud/main/gq-cloud.ps1" || {
        echo -e "${RED}Failed to download gq-cloud.ps1 script${RESET_COLOR}"
        exit 1
    }
    
    # Create a wrapper batch script
    echo "Creating batch wrapper..."
    cat > "$INSTALL_DIR/gq-cloud.bat" << EOL
@echo off
powershell.exe -ExecutionPolicy Bypass -File "%~dp0gq-cloud.ps1" %*
EOL
    
    # Add to Windows PATH using PowerShell
    echo "Adding to Windows PATH..."
    powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$INSTALL_DIR', 'User')"
    
    # Create PowerShell profile directory and add alias
    echo "Setting up PowerShell profile..."
    powershell.exe -Command "
        if (-not (Test-Path -Path \$PROFILE.CurrentUserAllHosts)) {
            New-Item -ItemType File -Path \$PROFILE.CurrentUserAllHosts -Force
        }
        Add-Content -Path \$PROFILE.CurrentUserAllHosts -Value \"\nSet-Alias gq-cloud '$INSTALL_DIR/gq-cloud.ps1'\"
    "
    
    echo -e "${GREEN}✓ Windows installation successful!${RESET_COLOR}"
    echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
    echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
    echo -e "\n${YELLOW}Note: You may need to restart your terminal to use the command${RESET_COLOR}"
}

# Main installation logic
case $OS in
    "Linux")
        setup_linux
        ;;
    "Windows")
        setup_windows
        ;;
    *)
        echo -e "${RED}Error: Unsupported operating system${RESET_COLOR}"
        exit 1
        ;;
esac

exit 0

# #!/bin/bash

# # Colors for output
# RESET_COLOR="\033[0m"
# BLUE="\033[1;34m"
# GREEN="\033[1;32m"
# RED="\033[0;31m"
# YELLOW="\033[0;33m"

# echo -e "${BLUE}GQ Cloud Management Tool Setup${RESET_COLOR}"
# echo "----------------------------------------"

# # Detect OS
# detect_os() {
#     case "$(uname -s)" in
#         Linux*)     
#             echo "Linux"
#             ;;
#         CYGWIN*|MINGW*|MSYS*)     
#             echo "Windows"
#             ;;
#         *)          
#             echo "Unknown"
#             ;;
#     esac
# }

# OS=$(detect_os)
# echo -e "Detected OS: ${YELLOW}$OS${RESET_COLOR}"

# # Function to set up Linux environment
# setup_linux() {
#     echo -e "\n${BLUE}Setting up Linux environment...${RESET_COLOR}"
    
#     # Create installation directory
#     INSTALL_DIR="$HOME/.gq-cloud"
#     mkdir -p "$INSTALL_DIR"
#     mkdir -p "$HOME/bin"
    
#     # Download the Linux script
#     echo "Downloading Linux script..."
#     curl -o "$INSTALL_DIR/gq-cloud" "https://raw.githubusercontent.com/your-repo/gq-cloud/main/gq-cloud.sh" || {
#         echo -e "${RED}Failed to download gq-cloud script${RESET_COLOR}"
#         exit 1
#     }
    
#     # Make it executable
#     chmod +x "$INSTALL_DIR/gq-cloud"
    
#     # Create symbolic link
#     ln -sf "$INSTALL_DIR/gq-cloud" "$HOME/bin/gq-cloud"
    
#     # Add to PATH if not already there
#     if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
#         echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
#         source "$HOME/.bashrc"
#     fi
    
#     # Verify installation
#     if [ -x "$HOME/bin/gq-cloud" ]; then
#         echo -e "${GREEN}✓ Linux installation successful!${RESET_COLOR}"
#         echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
#         echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
#     else
#         echo -e "${RED}✗ Installation failed${RESET_COLOR}"
#         exit 1
#     fi
# }

# # Function to set up Windows environment
# setup_windows() {
#     echo -e "\n${BLUE}Setting up Windows environment...${RESET_COLOR}"
    
#     # Create installation directory
#     INSTALL_DIR="$HOME/.gq-cloud"
#     mkdir -p "$INSTALL_DIR"
    
#     # Download the Windows PowerShell script
#     echo "Downloading Windows script..."
#     curl -o "$INSTALL_DIR/gq-cloud.ps1" "https://raw.githubusercontent.com/your-repo/gq-cloud/main/gq-cloud.ps1" || {
#         echo -e "${RED}Failed to download gq-cloud.ps1 script${RESET_COLOR}"
#         exit 1
#     }
    
#     # Create a wrapper batch script to make it easier to run from CMD
#     cat > "$INSTALL_DIR/gq-cloud.bat" << 'EOL'
# @echo off
# powershell.exe -ExecutionPolicy Bypass -File "%~dp0gq-cloud.ps1" %*
# EOL
    
#     # Add to Windows PATH using PowerShell
#     echo "Adding to Windows PATH..."
#     powershell.exe -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$INSTALL_DIR', 'User')"
    
#     # Create PowerShell profile directory if it doesn't exist
#     powershell.exe -Command "if (-not (Test-Path -Path \$PROFILE.CurrentUserAllHosts)) { New-Item -ItemType File -Path \$PROFILE.CurrentUserAllHosts -Force }"
    
#     # Add alias to PowerShell profile
#     echo "Adding PowerShell alias..."
#     powershell.exe -Command "Add-Content -Path \$PROFILE.CurrentUserAllHosts -Value \"`nSet-Alias gq-cloud '$INSTALL_DIR/gq-cloud.ps1'\""
    
#     echo -e "${GREEN}✓ Windows installation successful!${RESET_COLOR}"
#     echo -e "You can now use the ${BLUE}gq-cloud${RESET_COLOR} command."
#     echo -e "Try ${YELLOW}gq-cloud --help${RESET_COLOR} to get started."
#     echo -e "\n${YELLOW}Note: You may need to restart your terminal to use the command${RESET_COLOR}"
# }

# # Main installation logic
# case $OS in
#     "Linux")
#         setup_linux
#         ;;
#     "Windows")
#         setup_windows
#         ;;
#     *)
#         echo -e "${RED}Error: Unsupported operating system${RESET_COLOR}"
#         exit 1
#         ;;
# esac

# exit 0
